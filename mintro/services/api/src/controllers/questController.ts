import type { FastifyReply, FastifyRequest } from 'fastify';
import { questService } from '../services/questService.js';
import { gamificationService } from '../services/gamificationService.js';
import { questRepository } from '../repositories/questRepository.js';
import { Errors } from '../utils/errors.js';

export const questController = {
  async listActive(request: FastifyRequest, reply: FastifyReply) {
    const userId = request.user!.id;
    const quests = await questService.getActiveQuests(userId);
    reply.send({ data: quests });
  },

  async claim(request: FastifyRequest, reply: FastifyReply) {
    const userId = request.user!.id;
    const { userQuestId } = request.params as { userQuestId: string };

    if (!userQuestId) {
      throw Errors.badRequest('userQuestId is required');
    }

    const claimed = await questService.claimReward(userId, userQuestId);

    const templates = await questRepository.getAllTemplates();
    const template = templates.find((t) => t.id === claimed.quest_id);

    if (!template) {
      throw Errors.internal('Quest template not found for claimed quest');
    }

    const reward = await gamificationService.awardXpAndCoins(
      userId,
      template.xp_reward,
      template.coin_reward,
    );

    reply.send({
      data: {
        userQuest: claimed,
        reward: {
          xp: template.xp_reward,
          coins: template.coin_reward,
          newTotalXp: reward.newTotalXp,
          newCoins: reward.newCoins,
          newLevel: reward.newLevel,
          leveledUp: reward.leveledUp,
        },
      },
    });
  },
};
