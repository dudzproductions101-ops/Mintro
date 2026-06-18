-- ============================================================
-- MINTRO SEED DATA
-- File: supabase/seed.sql
-- Run AFTER 0001_init.sql and 0002_notifications.sql.
-- Safe to re-run: every insert uses ON CONFLICT to upsert by
-- natural key, so running this file twice won't create duplicates.
-- ============================================================

-- ============================================================
-- LEAGUES
-- 7 tiers matching the `league_tier` enum defined in 0001_init.sql.
-- promotion_count/demotion_count drive weeklyLeagueRotation.ts.
-- Master has no promotion target (handled in code via nextLeague()
-- returning null), so promotion_count there is unused but kept
-- non-null for schema consistency.
-- ============================================================
insert into public.leagues (tier, name, icon, rank_order, promotion_count, demotion_count, min_xp_to_enter)
values
  ('copper',  'Copper League',  'shield',         1, 10, 0,  0),
  ('bronze',  'Bronze League',  'shield-half',    2, 10, 5,  0),
  ('silver',  'Silver League',  'medal',          3, 10, 5,  0),
  ('gold',    'Gold League',    'trophy',         4, 10, 5,  0),
  ('emerald', 'Emerald League', 'gem',            5, 10, 5,  0),
  ('diamond', 'Diamond League', 'diamond',        6, 10, 5,  0),
  ('master',  'Master League',  'crown',          7, 0,  5,  0)
on conflict (tier) do update set
  name = excluded.name,
  icon = excluded.icon,
  rank_order = excluded.rank_order,
  promotion_count = excluded.promotion_count,
  demotion_count = excluded.demotion_count;

-- ============================================================
-- LEARNING PATHS
-- Matches the 5 paths referenced across the Skill Tree mockup
-- (Foundations, Credit & Debt, Investing, Tax Strategy) plus
-- Trust Funds & Long-Term Planning from the original brief.
-- color_hex values correspond to AppColors.path* in the Flutter theme.
-- ============================================================
insert into public.learning_paths (slug, title, description, icon, color_hex, difficulty, sort_order, is_premium)
values
  ('foundations',  'Foundations',                 'Core money concepts',          'dollar-sign', '#1F7A3D', 'beginner',     0, false),
  ('credit-debt',  'Credit & Debt',                'Manage credit wisely',         'credit-card', '#E8A100', 'intermediate', 1, false),
  ('investing',    'Investing',                    'Grow your wealth',             'trending-up', '#3B6FE0', 'advanced',     2, false),
  ('tax-strategy', 'Tax Strategy',                 'Keep more of what you earn',   'file-text',   '#8B5CF6', 'advanced',     3, false),
  ('trust-funds',  'Trust Funds & Long-Term Plan', 'Plan for generational wealth', 'shield',      '#0E9488', 'expert',       4, true)
on conflict (slug) do update set
  title = excluded.title,
  description = excluded.description,
  icon = excluded.icon,
  color_hex = excluded.color_hex,
  difficulty = excluded.difficulty,
  sort_order = excluded.sort_order,
  is_premium = excluded.is_premium;

-- ============================================================
-- LESSONS
-- `content` shapes match LessonContent / QuizQuestion in
-- lessonRepository.ts exactly, and correctAnswer shapes match what
-- lessonService.ts's scoreQuestion() expects per question type:
--   multiple_choice / true_false / scenario -> string
--   drag_drop                               -> string[]
--   match_pairs                             -> Record<string,string>
-- passingScore is checked against (correctCount/total)*100 in
-- lessonService.ts, so it must be a value reachable exactly or
-- below by some integer number of correct answers out of the total.
-- ============================================================

-- ---------- FOUNDATIONS PATH ----------

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'what-is-money', 'What is Money?', 'The three jobs money does for you', 'multiple_choice', 'coins', 10, 5, 0, 4,
'{
  "intro": "Before anything else, money has to do three jobs: be a medium of exchange, a unit of account, and a store of value.",
  "passingScore": 67,
  "questions": [
    {
      "id": "wim-q1",
      "type": "multiple_choice",
      "prompt": "Which of these is NOT one of the three core functions of money?",
      "options": [
        {"id": "a", "label": "Medium of exchange"},
        {"id": "b", "label": "Unit of account"},
        {"id": "c", "label": "Guarantee of future income"},
        {"id": "d", "label": "Store of value"}
      ],
      "correctAnswer": "c",
      "explanation": "Money does not guarantee future income — it stores value, but its purchasing power can still change over time (see inflation)."
    },
    {
      "id": "wim-q2",
      "type": "true_false",
      "prompt": "Barter (trading goods directly) is generally more efficient than using money.",
      "options": [
        {"id": "true", "label": "True"},
        {"id": "false", "label": "False"}
      ],
      "correctAnswer": "false",
      "explanation": "Barter requires both parties to want exactly what the other has — money removes that coincidence-of-wants problem."
    },
    {
      "id": "wim-q3",
      "type": "multiple_choice",
      "prompt": "If a coffee costs $4, the price tag is an example of money acting as a...",
      "options": [
        {"id": "a", "label": "Store of value"},
        {"id": "b", "label": "Unit of account"},
        {"id": "c", "label": "Legal tender requirement"}
      ],
      "correctAnswer": "b",
      "explanation": "A price expressed in a common unit (dollars) is money functioning as a unit of account — a shared way to compare value."
    }
  ]
}'::jsonb, false
from public.learning_paths where slug = 'foundations'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'inflation-basics', 'Inflation', 'Why a dollar today buys less tomorrow', 'multiple_choice', 'trending-up', 12, 6, 1, 5,
'{
  "intro": "Inflation is the rate at which prices rise — and purchasing power falls — over time.",
  "passingScore": 67,
  "questions": [
    {
      "id": "inf-q1",
      "type": "multiple_choice",
      "prompt": "If inflation is 3% per year, what happens to $100 sitting in a non-interest account after one year?",
      "options": [
        {"id": "a", "label": "It is still worth exactly $100"},
        {"id": "b", "label": "It can buy about $97 worth of last year''s goods"},
        {"id": "c", "label": "It automatically grows to $103"}
      ],
      "correctAnswer": "b",
      "explanation": "The number stays $100, but its purchasing power shrinks by roughly the inflation rate."
    },
    {
      "id": "inf-q2",
      "type": "true_false",
      "prompt": "Mild, steady inflation is generally considered a sign of a healthy, growing economy by most central banks.",
      "options": [
        {"id": "true", "label": "True"},
        {"id": "false", "label": "False"}
      ],
      "correctAnswer": "true",
      "explanation": "Most central banks (e.g. the Fed, ECB) target a low positive inflation rate, often around 2%, rather than 0%."
    },
    {
      "id": "inf-q3",
      "type": "multiple_choice",
      "prompt": "Which of these is most directly hurt by unexpectedly high inflation?",
      "options": [
        {"id": "a", "label": "Someone holding a lot of cash"},
        {"id": "b", "label": "Someone who owns real estate"},
        {"id": "c", "label": "Someone with a fixed-rate mortgage"}
      ],
      "correctAnswer": "a",
      "explanation": "Cash loses purchasing power directly under inflation; real assets and fixed-rate debt can actually benefit relative to cash."
    }
  ]
}'::jsonb, false
from public.learning_paths where slug = 'foundations'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'supply-and-demand', 'Supply and Demand', 'The forces behind every price', 'drag_drop', 'bar-chart', 12, 6, 2, 5,
'{
  "intro": "Order the events correctly: what happens to price when supply drops but demand stays the same?",
  "passingScore": 100,
  "questions": [
    {
      "id": "sd-q1",
      "type": "drag_drop",
      "prompt": "Put these in the correct cause-and-effect order: [Price rises] [Supply drops] [Buyers compete for fewer goods]",
      "options": [
        {"id": "supply_drops", "label": "Supply drops"},
        {"id": "buyers_compete", "label": "Buyers compete for fewer goods"},
        {"id": "price_rises", "label": "Price rises"}
      ],
      "correctAnswer": ["supply_drops", "buyers_compete", "price_rises"],
      "explanation": "A drop in supply means the same number of buyers are chasing fewer goods, which pushes the price up."
    }
  ]
}'::jsonb, false
from public.learning_paths where slug = 'foundations'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'budget-basics', 'Budget Basics', '50/30/20 rule explained', 'multiple_choice', 'piggy-bank', 10, 5, 3, 4,
'{
  "intro": "The 50/30/20 rule is a simple starting framework for splitting take-home pay.",
  "passingScore": 67,
  "questions": [
    {
      "id": "bb-q1",
      "type": "multiple_choice",
      "prompt": "In the 50/30/20 rule, what does the 50% typically cover?",
      "options": [
        {"id": "a", "label": "Needs — rent, groceries, utilities"},
        {"id": "b", "label": "Wants — entertainment, dining out"},
        {"id": "c", "label": "Savings and debt repayment"}
      ],
      "correctAnswer": "a",
      "explanation": "50% needs, 30% wants, 20% savings/debt repayment is the standard split."
    },
    {
      "id": "bb-q2",
      "type": "multiple_choice",
      "prompt": "On take-home pay of $3,000/month, how much does the rule suggest for savings and debt repayment?",
      "options": [
        {"id": "a", "label": "$300"},
        {"id": "b", "label": "$600"},
        {"id": "c", "label": "$900"}
      ],
      "correctAnswer": "b",
      "explanation": "20% of $3,000 is $600."
    },
    {
      "id": "bb-q3",
      "type": "true_false",
      "prompt": "The 50/30/20 rule is a strict legal requirement for budgeting.",
      "options": [
        {"id": "true", "label": "True"},
        {"id": "false", "label": "False"}
      ],
      "correctAnswer": "false",
      "explanation": "It is a guideline, not a rule enforced by anyone — useful as a starting point, not a mandate."
    }
  ]
}'::jsonb, false
from public.learning_paths where slug = 'foundations'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'compound-interest', 'Compound Interest', 'How money grows over time', 'multiple_choice', 'trending-up', 15, 7, 4, 5,
'{
  "intro": "Compound interest means you earn returns not just on your original money, but on the returns it already made.",
  "passingScore": 67,
  "questions": [
    {
      "id": "ci-q1",
      "type": "multiple_choice",
      "prompt": "You invest $1,000 at 10% annual compound interest. After year 1, you have $1,100. What do you have after year 2?",
      "options": [
        {"id": "a", "label": "$1,200"},
        {"id": "b", "label": "$1,210"},
        {"id": "c", "label": "$1,100"}
      ],
      "correctAnswer": "b",
      "explanation": "Year 2 grows from $1,100, not the original $1,000: $1,100 x 1.10 = $1,210. The extra $10 versus simple interest is the compounding effect."
    },
    {
      "id": "ci-q2",
      "type": "true_false",
      "prompt": "The earlier you start investing, the more time compound interest has to work, even at the same contribution amount.",
      "options": [
        {"id": "true", "label": "True"},
        {"id": "false", "label": "False"}
      ],
      "correctAnswer": "true",
      "explanation": "Time is the single biggest lever in compounding — starting 10 years earlier often outweighs contributing more money later."
    },
    {
      "id": "ci-q3",
      "type": "multiple_choice",
      "prompt": "Compound interest can also work against you. In which situation?",
      "options": [
        {"id": "a", "label": "A high-yield savings account"},
        {"id": "b", "label": "Credit card debt with a high APR"},
        {"id": "c", "label": "An employer 401(k) match"}
      ],
      "correctAnswer": "b",
      "explanation": "Unpaid credit card balances compound against you the same way investments compound for you — which is why high-APR debt grows so fast if left unpaid."
    }
  ]
}'::jsonb, false
from public.learning_paths where slug = 'foundations'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

-- ---------- CREDIT & DEBT PATH ----------

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'what-is-a-credit-score', 'What is a Credit Score?', 'The number lenders look at first', 'multiple_choice', 'credit-card', 12, 6, 0, 5,
'{
  "intro": "A credit score is a three-digit number summarizing how reliably you have repaid borrowed money in the past.",
  "passingScore": 67,
  "questions": [
    {
      "id": "cs-q1",
      "type": "multiple_choice",
      "prompt": "Which factor typically has the LARGEST impact on a FICO credit score?",
      "options": [
        {"id": "a", "label": "Payment history"},
        {"id": "b", "label": "Number of credit cards you own"},
        {"id": "c", "label": "Your income"}
      ],
      "correctAnswer": "a",
      "explanation": "Payment history is the single largest factor in most scoring models — income is not even part of the calculation."
    },
    {
      "id": "cs-q2",
      "type": "true_false",
      "prompt": "Your income is one of the factors used to calculate your credit score.",
      "options": [
        {"id": "true", "label": "True"},
        {"id": "false", "label": "False"}
      ],
      "correctAnswer": "false",
      "explanation": "Credit scores are based on borrowing and repayment behavior, not income directly — though income affects what lenders approve you for."
    },
    {
      "id": "cs-q3",
      "type": "multiple_choice",
      "prompt": "What is \"credit utilization\"?",
      "options": [
        {"id": "a", "label": "How many different lenders you have used"},
        {"id": "b", "label": "The percentage of your available credit you are currently using"},
        {"id": "c", "label": "How often you check your own credit report"}
      ],
      "correctAnswer": "b",
      "explanation": "Utilization is balance divided by credit limit — keeping it low (commonly cited as under 30%) tends to help your score."
    }
  ]
}'::jsonb, false
from public.learning_paths where slug = 'credit-debt'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'good-debt-vs-bad-debt', 'Good Debt vs Bad Debt', 'Not all borrowing is the same', 'scenario', 'scale', 12, 6, 1, 5,
'{
  "intro": "Debt itself is not good or bad — what matters is what it is used for and its cost.",
  "passingScore": 67,
  "questions": [
    {
      "id": "gd-q1",
      "type": "scenario",
      "prompt": "You have $2,000 in credit card debt at 24% APR, and also a low-rate student loan at 4% APR you are slowly paying down on schedule. You get a surprise $2,000 bonus. What is the financially soundest move?",
      "options": [
        {"id": "a", "label": "Pay off the entire credit card balance"},
        {"id": "b", "label": "Pay extra on the student loan instead"},
        {"id": "c", "label": "Split it evenly between both"}
      ],
      "correctAnswer": "a",
      "explanation": "24% APR debt compounds far faster than 4% APR debt — eliminating the more expensive balance first saves the most money overall."
    },
    {
      "id": "gd-q2",
      "type": "multiple_choice",
      "prompt": "Which of these is usually considered an example of \"good debt\"?",
      "options": [
        {"id": "a", "label": "A mortgage on a home that can appreciate in value"},
        {"id": "b", "label": "A payday loan to cover a vacation"},
        {"id": "c", "label": "Credit card debt for everyday groceries"}
      ],
      "correctAnswer": "a",
      "explanation": "Debt used to acquire an appreciating or income-generating asset, at a reasonable rate, is the classic \"good debt\" example."
    },
    {
      "id": "gd-q3",
      "type": "true_false",
      "prompt": "All debt should be paid off as fast as possible regardless of interest rate.",
      "options": [
        {"id": "true", "label": "True"},
        {"id": "false", "label": "False"}
      ],
      "correctAnswer": "false",
      "explanation": "Low-rate debt (e.g. some mortgages) can sometimes make sense to pay down slowly while directing extra money toward higher-return investments instead."
    }
  ]
}'::jsonb, false
from public.learning_paths where slug = 'credit-debt'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'credit-terms-match', 'Credit Terms', 'Match the term to its definition', 'match_pairs', 'book', 12, 6, 2, 5,
'{
  "intro": "Match each credit term to its correct definition.",
  "passingScore": 100,
  "questions": [
    {
      "id": "ct-q1",
      "type": "match_pairs",
      "prompt": "Match each term to its definition.",
      "pairs": [
        {"left": "apr", "right": "def_apr"},
        {"left": "minimum_payment", "right": "def_min"},
        {"left": "grace_period", "right": "def_grace"}
      ],
      "options": [
        {"id": "apr", "label": "APR"},
        {"id": "minimum_payment", "label": "Minimum Payment"},
        {"id": "grace_period", "label": "Grace Period"},
        {"id": "def_apr", "label": "The yearly cost of borrowing, expressed as a percentage"},
        {"id": "def_min", "label": "The smallest amount you must pay to avoid being marked late"},
        {"id": "def_grace", "label": "The window after your statement closes where no interest accrues if paid in full"}
      ],
      "correctAnswer": {
        "apr": "def_apr",
        "minimum_payment": "def_min",
        "grace_period": "def_grace"
      },
      "explanation": "Paying only the minimum payment, while technically avoiding late fees, still accrues interest at the full APR on the remaining balance."
    }
  ]
}'::jsonb, false
from public.learning_paths where slug = 'credit-debt'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

-- ---------- INVESTING PATH ----------

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'stocks-vs-bonds', 'Stocks vs Bonds', 'Ownership versus lending', 'multiple_choice', 'trending-up', 15, 7, 0, 5,
'{
  "intro": "A stock makes you a partial owner of a company. A bond makes you a lender to one (or to a government).",
  "passingScore": 67,
  "questions": [
    {
      "id": "sb-q1",
      "type": "multiple_choice",
      "prompt": "If you own a share of a company''s stock, you are a...",
      "options": [
        {"id": "a", "label": "Lender to the company"},
        {"id": "b", "label": "Partial owner of the company"},
        {"id": "c", "label": "Employee of the company"}
      ],
      "correctAnswer": "b",
      "explanation": "A share represents fractional ownership — you participate in the company''s gains and losses."
    },
    {
      "id": "sb-q2",
      "type": "true_false",
      "prompt": "Bonds are generally considered lower-risk than stocks.",
      "options": [
        {"id": "true", "label": "True"},
        {"id": "false", "label": "False"}
      ],
      "correctAnswer": "true",
      "explanation": "Bondholders are paid before stockholders if a company runs into trouble, and bond returns are typically more predictable — though not risk-free."
    },
    {
      "id": "sb-q3",
      "type": "multiple_choice",
      "prompt": "What does a bond''s \"yield\" represent?",
      "options": [
        {"id": "a", "label": "The return an investor receives for lending money"},
        {"id": "b", "label": "The company''s total annual profit"},
        {"id": "c", "label": "The number of bonds issued"}
      ],
      "correctAnswer": "a",
      "explanation": "Yield is the return the lender (bondholder) earns, generally tied to the interest rate the borrower agreed to pay."
    }
  ]
}'::jsonb, false
from public.learning_paths where slug = 'investing'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'index-funds-101', 'Index Funds', 'Buying the whole market at once', 'multiple_choice', 'layers', 15, 7, 1, 5,
'{
  "intro": "An index fund holds a broad basket of stocks (e.g. the S&P 500) rather than betting on a single company.",
  "passingScore": 67,
  "questions": [
    {
      "id": "if-q1",
      "type": "multiple_choice",
      "prompt": "What is the main advantage of an index fund over picking individual stocks?",
      "options": [
        {"id": "a", "label": "It guarantees higher returns every year"},
        {"id": "b", "label": "Instant diversification across many companies at low cost"},
        {"id": "c", "label": "It is immune to market downturns"}
      ],
      "correctAnswer": "b",
      "explanation": "Diversification reduces the risk of any single company''s failure wiping out your investment — but index funds still rise and fall with the overall market."
    },
    {
      "id": "if-q2",
      "type": "true_false",
      "prompt": "Index funds are immune to losing value during a market downturn.",
      "options": [
        {"id": "true", "label": "True"},
        {"id": "false", "label": "False"}
      ],
      "correctAnswer": "false",
      "explanation": "Index funds track the market, so they fall when the overall market falls — diversification reduces single-company risk, not market-wide risk."
    },
    {
      "id": "if-q3",
      "type": "multiple_choice",
      "prompt": "Why do index funds typically have lower fees than actively managed funds?",
      "options": [
        {"id": "a", "label": "They simply track an index rather than paying analysts to pick stocks"},
        {"id": "b", "label": "They are not allowed to charge fees by law"},
        {"id": "c", "label": "They only invest in cheap stocks"}
      ],
      "correctAnswer": "a",
      "explanation": "Passive tracking requires far less active research and trading than stock-picking, which is reflected in lower management fees."
    }
  ]
}'::jsonb, false
from public.learning_paths where slug = 'investing'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'investment-simulation', 'Invest $1,000', 'Choose where to put your money and see the outcome', 'simulation', 'activity', 18, 10, 2, 6,
'{
  "intro": "You have $1,000 to invest for one year. Pick stocks, bonds, or a savings account, then see a realistic range of outcomes.",
  "passingScore": 67,
  "simulation": {
    "startingAmount": 1000,
    "choices": [
      {"id": "stocks", "label": "Stocks (higher risk, higher potential return)", "outcomeRange": [-150, 250]},
      {"id": "bonds", "label": "Bonds (moderate, more predictable)", "outcomeRange": [-20, 60]},
      {"id": "savings", "label": "Savings Account (lowest risk, lowest return)", "outcomeRange": [10, 40]}
    ]
  },
  "questions": [
    {
      "id": "sim-q1",
      "type": "multiple_choice",
      "prompt": "Which option has the widest range of possible outcomes, both up and down?",
      "options": [
        {"id": "stocks", "label": "Stocks"},
        {"id": "bonds", "label": "Bonds"},
        {"id": "savings", "label": "Savings Account"}
      ],
      "correctAnswer": "stocks",
      "explanation": "Stocks carry the most volatility — the largest potential gains, but also the only realistic chance of an outright loss in this simulation."
    },
    {
      "id": "sim-q2",
      "type": "true_false",
      "prompt": "A savings account guarantees you will never lose nominal value, even though inflation may erode purchasing power.",
      "options": [
        {"id": "true", "label": "True"},
        {"id": "false", "label": "False"}
      ],
      "correctAnswer": "true",
      "explanation": "The dollar amount in a savings account does not go down — but its purchasing power can still shrink if inflation outpaces the interest rate paid."
    }
  ]
}'::jsonb, false
from public.learning_paths where slug = 'investing'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

-- ---------- TAX STRATEGY PATH ----------

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'how-tax-brackets-work', 'How Tax Brackets Work', 'Why a raise never costs you money', 'multiple_choice', 'file-text', 15, 7, 0, 5,
'{
  "intro": "Tax brackets are marginal, not flat — only the income inside each bracket is taxed at that bracket''s rate.",
  "passingScore": 67,
  "questions": [
    {
      "id": "tb-q1",
      "type": "true_false",
      "prompt": "If a raise pushes you into a higher tax bracket, all of your income gets taxed at the new, higher rate.",
      "options": [
        {"id": "true", "label": "True"},
        {"id": "false", "label": "False"}
      ],
      "correctAnswer": "false",
      "explanation": "Only the portion of income that falls inside the new bracket is taxed at the higher rate — this is the single most common tax misconception."
    },
    {
      "id": "tb-q2",
      "type": "multiple_choice",
      "prompt": "What is the difference between your \"marginal\" tax rate and your \"effective\" tax rate?",
      "options": [
        {"id": "a", "label": "Marginal is the rate on your last dollar earned; effective is your overall average rate"},
        {"id": "b", "label": "They are always the same number"},
        {"id": "c", "label": "Effective rate only applies to self-employed people"}
      ],
      "correctAnswer": "a",
      "explanation": "Your effective rate (total tax / total income) is almost always lower than your marginal rate (the rate on your top bracket)."
    },
    {
      "id": "tb-q3",
      "type": "multiple_choice",
      "prompt": "A pre-tax 401(k) contribution does what to your taxable income for the year?",
      "options": [
        {"id": "a", "label": "Increases it"},
        {"id": "b", "label": "Has no effect on it"},
        {"id": "c", "label": "Reduces it"}
      ],
      "correctAnswer": "c",
      "explanation": "Pre-tax contributions are subtracted from taxable income before tax is calculated, which is why they lower your tax bill in the year you contribute."
    }
  ]
}'::jsonb, false
from public.learning_paths where slug = 'tax-strategy'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'deductions-vs-credits', 'Deductions vs Credits', 'Two different ways to lower your bill', 'multiple_choice', 'percent', 15, 7, 1, 5,
'{
  "intro": "Both reduce what you owe, but they work differently — and credits are usually worth more.",
  "passingScore": 67,
  "questions": [
    {
      "id": "dc-q1",
      "type": "multiple_choice",
      "prompt": "A $1,000 tax credit reduces your tax bill by...",
      "options": [
        {"id": "a", "label": "$1,000, directly"},
        {"id": "b", "label": "$1,000 multiplied by your tax rate"},
        {"id": "c", "label": "Nothing — credits only apply to businesses"}
      ],
      "correctAnswer": "a",
      "explanation": "A credit is a dollar-for-dollar reduction in tax owed, which is why credits are generally more valuable than an equal-sized deduction."
    },
    {
      "id": "dc-q2",
      "type": "multiple_choice",
      "prompt": "A $1,000 tax deduction at a 22% marginal rate reduces your tax bill by approximately...",
      "options": [
        {"id": "a", "label": "$1,000"},
        {"id": "b", "label": "$220"},
        {"id": "c", "label": "$0"}
      ],
      "correctAnswer": "b",
      "explanation": "A deduction reduces taxable income, so its value depends on your marginal rate: $1,000 x 22% = $220 saved, not the full $1,000."
    },
    {
      "id": "dc-q3",
      "type": "true_false",
      "prompt": "Tax credits and tax deductions provide identical savings for any given dollar amount.",
      "options": [
        {"id": "true", "label": "True"},
        {"id": "false", "label": "False"}
      ],
      "correctAnswer": "false",
      "explanation": "Credits reduce tax owed directly; deductions reduce taxable income and are therefore worth less per dollar at any rate below 100%."
    }
  ]
}'::jsonb, false
from public.learning_paths where slug = 'tax-strategy'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

-- ---------- TRUST FUNDS & LONG-TERM PLANNING PATH (premium) ----------

insert into public.lessons (path_id, slug, title, description, lesson_type, icon, xp_reward, coin_reward, sort_order, estimated_minutes, content, is_premium)
select id, 'what-is-a-trust', 'What is a Trust?', 'Passing on wealth with control attached', 'multiple_choice', 'shield', 20, 10, 0, 6,
'{
  "intro": "A trust is a legal arrangement where one party holds and manages assets on behalf of another, often used to control how and when wealth is passed on.",
  "passingScore": 67,
  "questions": [
    {
      "id": "tr-q1",
      "type": "multiple_choice",
      "prompt": "In a trust, who is the \"trustee\"?",
      "options": [
        {"id": "a", "label": "The person who eventually receives the assets"},
        {"id": "b", "label": "The person or institution managing the assets according to the trust''s rules"},
        {"id": "c", "label": "A government tax official"}
      ],
      "correctAnswer": "b",
      "explanation": "The trustee manages the assets on behalf of the beneficiary, following the terms the trust''s creator (the grantor) set out."
    },
    {
      "id": "tr-q2",
      "type": "true_false",
      "prompt": "Trusts are only useful for extremely wealthy families.",
      "options": [
        {"id": "true", "label": "True"},
        {"id": "false", "label": "False"}
      ],
      "correctAnswer": "false",
      "explanation": "Trusts are also commonly used for more modest goals like controlling when a minor inherits money, or avoiding probate delays — not exclusively for large estates."
    },
    {
      "id": "tr-q3",
      "type": "multiple_choice",
      "prompt": "What is one common reason someone sets up a trust instead of a simple will?",
      "options": [
        {"id": "a", "label": "To avoid ever paying any taxes"},
        {"id": "b", "label": "To control the timing or conditions under which beneficiaries receive assets"},
        {"id": "c", "label": "Trusts are required by law for everyone"}
      ],
      "correctAnswer": "b",
      "explanation": "A will generally transfers assets outright; a trust can stagger distributions, attach conditions, or skip the public probate process."
    }
  ]
}'::jsonb, true
from public.learning_paths where slug = 'trust-funds'
on conflict (slug) do update set content = excluded.content, title = excluded.title;

-- ============================================================
-- QUESTS (templates)
-- One or more per quest_type x period combination, matching the
-- enums in 0001_init.sql. getPeriodRange() in questRepository.ts
-- anchors daily/weekly/monthly windows automatically — these rows
-- are just the static templates that get instantiated per-user
-- per-period via ensureActiveQuest().
-- ============================================================

insert into public.quests (slug, title, description, quest_type, period, target_value, xp_reward, coin_reward, icon, is_featured)
values
  -- Daily quests
  ('daily-three-lessons', 'Three a Day', 'Complete 3 lessons today', 'complete_lessons', 'daily', 3, 30, 50, 'book-open', false),
  ('daily-fifty-xp', 'Fifty XP', 'Earn 100 XP today', 'earn_xp', 'daily', 100, 20, 30, 'bolt', false),
  ('daily-save-five', 'Save Five', 'Add at least $5 to any savings goal today', 'save_money', 'daily', 5, 25, 40, 'piggy-bank', false),

  -- Weekly quests
  ('weekly-budget-builder', 'Budget Builder', 'Track expenses in 3 categories for 5 consecutive days', 'complete_lessons', 'weekly', 5, 60, 500, 'piggy-bank', false),
  ('weekly-streak-keeper', 'Streak Keeper', 'Maintain your streak for 7 days this week', 'maintain_streak', 'weekly', 7, 70, 300, 'whatshot', false),
  ('weekly-path-progress', 'Path Progress', 'Complete 10 lessons this week', 'complete_lessons', 'weekly', 10, 100, 600, 'route', false),
  ('weekly-saver', 'Weekly Saver', 'Save $25 toward any goal this week', 'save_money', 'weekly', 25, 80, 400, 'savings', false),

  -- Monthly quests
  ('monthly-master', 'Monthly Master', 'Complete all four weekly quests this month', 'complete_lessons', 'monthly', 4, 200, 2000, 'trophy', true),
  ('monthly-path-finisher', 'Path Finisher', 'Complete an entire learning path this month', 'complete_path', 'monthly', 1, 150, 1000, 'flag', false),
  ('monthly-big-saver', 'Big Saver', 'Save $100 toward any goal this month', 'save_money', 'monthly', 100, 150, 1200, 'gem', false)
on conflict (slug) do update set
  title = excluded.title,
  description = excluded.description,
  target_value = excluded.target_value,
  xp_reward = excluded.xp_reward,
  coin_reward = excluded.coin_reward,
  icon = excluded.icon,
  is_featured = excluded.is_featured;

-- ============================================================
-- ACHIEVEMENTS
--
-- The original product brief asked for 100+ achievements. This seed
-- file ships 25 real ones instead, for one specific reason: as of
-- this build (Parts A-G), there is no job that evaluates achievement
-- progress and inserts user_achievements rows automatically — see
-- README.md "Scaffolded but not fully built". Seeding 100 rows here
-- would create 100 entries that the Profile screen's achievement
-- grid renders as permanently "locked," with nothing in the codebase
-- that could ever unlock them. 25 well-chosen, clearly-defined
-- achievements is more useful right now than 100 inert ones —
-- when the evaluation job from README's Future Improvements item #2
-- is built, extending this list to 100+ is a pure data-entry task,
-- not a schema or code change.
--
-- requirement_type / requirement_value are read by that future job;
-- they are not yet enforced by any code in this build, but are
-- included now so the data model is ready when the job is written.
-- ============================================================

insert into public.achievements (slug, title, description, icon, category, requirement_type, requirement_value, xp_reward, coin_reward, sort_order)
values
  -- Savings
  ('beginner-saver', 'Beginner Saver', 'Save your first $100 toward any goal', 'piggy-bank', 'savings', 'total_saved', 100, 50, 100, 0),
  ('serious-saver', 'Serious Saver', 'Save $1,000 toward any goal', 'piggy-bank', 'savings', 'total_saved', 1000, 150, 500, 1),
  ('goal-getter', 'Goal Getter', 'Complete your first savings goal', 'flag', 'savings', 'goals_completed', 1, 100, 250, 2),
  ('goal-crusher', 'Goal Crusher', 'Complete 5 savings goals', 'flag', 'savings', 'goals_completed', 5, 300, 1000, 3),
  ('emergency-ready', 'Emergency Ready', 'Fully fund an Emergency Fund goal', 'shield', 'savings', 'emergency_fund_completed', 1, 200, 600, 4),

  -- Learning
  ('first-lesson', 'First Step', 'Complete your first lesson', 'book-open', 'learning', 'lessons_completed', 1, 10, 25, 5),
  ('financial-apprentice', 'Financial Apprentice', 'Complete 25 lessons', 'book-open', 'learning', 'lessons_completed', 25, 100, 300, 6),
  ('financial-scholar', 'Financial Scholar', 'Complete 50 lessons', 'graduation-cap', 'learning', 'lessons_completed', 50, 200, 600, 7),
  ('financial-master', 'Financial Master', 'Complete 100 lessons', 'graduation-cap', 'learning', 'lessons_completed', 100, 400, 1200, 8),
  ('foundations-complete', 'Foundations Graduate', 'Complete the entire Foundations path', 'dollar-sign', 'learning', 'path_completed', 1, 150, 400, 9),
  ('investor', 'Investor', 'Complete the entire Investing path', 'trending-up', 'learning', 'path_completed', 1, 200, 500, 10),
  ('tax-strategist', 'Tax Strategist', 'Complete the entire Tax Strategy path', 'file-text', 'learning', 'path_completed', 1, 200, 500, 11),
  ('economics-master', 'Economics Master', 'Complete every learning path', 'crown', 'learning', 'all_paths_completed', 1, 1000, 5000, 12),
  ('perfect-score', 'Perfect Score', 'Score 100% on any lesson', 'star', 'learning', 'perfect_lesson_score', 1, 30, 75, 13),
  ('quiz-whiz', 'Quiz Whiz', 'Score 100% on 10 different lessons', 'star', 'learning', 'perfect_lesson_score_count', 10, 200, 500, 14),

  -- Streaks
  ('week-warrior', 'Week Warrior', 'Reach a 7-day streak', 'whatshot', 'streaks', 'streak_days', 7, 50, 150, 15),
  ('consistency-king', 'Consistency King', 'Reach a 30-day streak', 'whatshot', 'streaks', 'streak_days', 30, 200, 750, 16),
  ('streak-legend', 'Streak Legend', 'Reach a 100-day streak', 'whatshot', 'streaks', 'streak_days', 100, 600, 2000, 17),
  ('streak-immortal', 'Streak Immortal', 'Reach a 365-day streak', 'whatshot', 'streaks', 'streak_days', 365, 2000, 10000, 18),

  -- Quests
  ('quest-starter', 'Quest Starter', 'Complete your first quest', 'bolt', 'quests', 'quests_completed', 1, 20, 50, 19),
  ('quest-regular', 'Quest Regular', 'Complete 25 quests', 'bolt', 'quests', 'quests_completed', 25, 150, 400, 20),
  ('monthly-champion', 'Monthly Champion', 'Complete a Monthly Master quest', 'trophy', 'quests', 'monthly_master_completed', 1, 250, 1000, 21),

  -- Leagues
  ('first-promotion', 'On the Rise', 'Get promoted to a higher league for the first time', 'arrow-up', 'leagues', 'promotions', 1, 50, 200, 22),
  ('emerald-reached', 'Emerald Status', 'Reach the Emerald League', 'gem', 'leagues', 'league_reached', 5, 300, 800, 23),
  ('master-league', 'Master of Mintro', 'Reach the Master League', 'crown', 'leagues', 'league_reached', 7, 1000, 5000, 24)
on conflict (slug) do update set
  title = excluded.title,
  description = excluded.description,
  requirement_type = excluded.requirement_type,
  requirement_value = excluded.requirement_value,
  xp_reward = excluded.xp_reward,
  coin_reward = excluded.coin_reward,
  sort_order = excluded.sort_order;

-- ============================================================
-- NOTE ON DEMO/TEST USERS
--
-- This file intentionally does NOT insert rows into auth.users.
-- Supabase manages that table through its Auth service, not as a
-- plain table you can INSERT into directly — the password hashing,
-- session handling, and related auth.* tables (identities, sessions)
-- need to go through the Auth API to stay consistent. Create test
-- accounts via Authentication -> Users -> Add User in the Supabase
-- dashboard (see TUTORIAL.md Part 3.3), or via the Admin API:
--
--   POST {SUPABASE_URL}/auth/v1/admin/users
--   Authorization: Bearer {SUPABASE_SERVICE_ROLE_KEY}
--   { "email": "demo@mintro.app", "password": "...", "email_confirm": true }
--
-- The 0001_init.sql trigger `handle_new_user` automatically creates
-- a matching `profiles` row the moment a user signs up, so once a
-- test user exists, they immediately have a profile to seed
-- `user_lessons` / `goals` / `league_members` test rows against if
-- you want a fully populated demo account rather than an empty one.
-- ============================================================

-- ============================================================
-- VERIFICATION
-- Run this block after the inserts above to confirm row counts
-- look sane. Expected: 7 leagues, 5 paths, 14 lessons, 10 quests,
-- 25 achievements.
-- ============================================================
select
  (select count(*) from public.leagues)        as league_count,
  (select count(*) from public.learning_paths) as path_count,
  (select count(*) from public.lessons)        as lesson_count,
  (select count(*) from public.quests)         as quest_count,
  (select count(*) from public.achievements)   as achievement_count;
