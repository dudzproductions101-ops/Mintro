import admin from 'firebase-admin';
import { env } from '../config/env.js';
import { supabaseAdmin } from '../config/supabase.js';
import { logger } from '../utils/logger.js';

let firebaseApp: admin.app.App | null = null;

function getFirebaseApp(): admin.app.App | null {
  if (!env.FIREBASE_PROJECT_ID || !env.FIREBASE_CLIENT_EMAIL || !env.FIREBASE_PRIVATE_KEY) {
    logger.warn('Firebase credentials not configured — push notifications disabled');
    return null;
  }

  if (!firebaseApp) {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: env.FIREBASE_PROJECT_ID,
        clientEmail: env.FIREBASE_CLIENT_EMAIL,
        privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      }),
    });
  }

  return firebaseApp;
}

export type NotificationType =
  | 'daily_reminder'
  | 'streak_reminder'
  | 'goal_reminder'
  | 'achievement_unlocked'
  | 'league_promotion'
  | 'league_demotion';

interface SendOptions {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, string>;
}

const PREF_KEY_BY_TYPE: Record<NotificationType, string> = {
  daily_reminder: 'daily_reminder',
  streak_reminder: 'streak_reminder',
  goal_reminder: 'goal_reminder',
  achievement_unlocked: 'achievement_alerts',
  league_promotion: 'league_promotion',
  league_demotion: 'league_promotion',
};

export const pushService = {
  /**
   * Sends a push notification to a single user, respecting their
   * notification preferences, and logs it to `notifications_log`
   * for display in the in-app Notifications screen.
   */
  async sendToUser(options: SendOptions): Promise<void> {
    const { data: profile, error } = await supabaseAdmin
      .from('profiles')
      .select('fcm_token, notification_prefs')
      .eq('id', options.userId)
      .single();

    if (error || !profile) {
      logger.warn({ userId: options.userId }, 'Cannot send notification — profile not found');
      return;
    }

    const prefKey = PREF_KEY_BY_TYPE[options.type];
    const prefs = (profile.notification_prefs ?? {}) as Record<string, boolean>;

    if (prefs[prefKey] === false) {
      logger.info(
        { userId: options.userId, type: options.type },
        'Notification skipped — user preference disabled',
      );
    } else {
      const app = getFirebaseApp();

      if (app && profile.fcm_token) {
        try {
          await admin.messaging(app).send({
            token: profile.fcm_token,
            notification: { title: options.title, body: options.body },
            data: options.data ?? {},
          });
        } catch (err) {
          logger.error({ err, userId: options.userId }, 'Failed to send FCM push');
        }
      }
    }

    // Always log, even if push delivery was skipped, so the in-app
    // Notifications screen reflects the full history.
    const { error: logError } = await supabaseAdmin.from('notifications_log').insert({
      user_id: options.userId,
      type: options.type,
      title: options.title,
      body: options.body,
      data: options.data ?? {},
    });

    if (logError) {
      logger.error({ err: logError, userId: options.userId }, 'Failed to write notification log');
    }
  },

  async sendToUsers(userIds: string[], options: Omit<SendOptions, 'userId'>): Promise<void> {
    await Promise.all(userIds.map((userId) => this.sendToUser({ ...options, userId })));
  },
};
