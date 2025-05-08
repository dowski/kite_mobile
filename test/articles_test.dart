import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kite_mobile/articles.dart';

void main() {
  group('Article from JSON', () {
    final article = Article.fromJson(jsonDecode(articleJson) as Map<String, dynamic>);
    test('has proper headline', () {
      expect(article?.headline.title, 'Inter Milan triumphs in historic Champions League semi-final');
      expect(article?.headline.category, 'Football');
    });

    test('has proper location', () {
      expect(article?.location, 'Milan, Italy');
    });

    test('has proper summary', () {
      expect(article?.summary, 'Inter Milan has secured a place in the Champions League final after defeating Barcelona 4-3 in extra time (7-6 on aggregate) in an extraordinary semi-final match at San Siro. The thrilling contest featured remarkable comebacks from both sides, with substitute Davide Frattesi scoring the decisive goal in the 99th minute of extra time. This victory sends Inter to their second Champions League final in three years, where they will face either Arsenal or Paris Saint-Germain.');
    });

    test('has proper external articles', () {
      expect(article?.externalArticles, hasLength(7));
      // Unique properties.
      expect(article?.externalArticles.map((article) => article.title).toSet(), hasLength(7));
      expect(article?.externalArticles.map((article) => article.link).toSet(), hasLength(7));
    });

    test('has proper images', () {
      expect(article?.image1, isNotNull);
      expect(article?.image2, isNotNull);
      expect(article?.image1, isNot(equals(article?.image2)));
    });

    test('has proper talking points', () {
      expect(article?.talkingPoints, hasLength(5));
      // Unique properties.
      expect(article?.talkingPoints.map((point) => point.heading).toSet(), hasLength(5));
      expect(article?.talkingPoints.map((point) => point.body).toSet(), hasLength(5));
      // No blank leading characters.
      expect(article?.talkingPoints.every((point) => point.body.startsWith(' ')), isFalse);
    });
  });
}

const articleJson = r'''
{
  "cluster_number": 1,
  "unique_domains": 5,
  "number_of_titles": 7,
  "category": "Football",
  "title": "Inter Milan triumphs in historic Champions League semi-final",
  "short_summary": "Inter Milan has secured a place in the Champions League final after defeating Barcelona 4-3 in extra time (7-6 on aggregate) in an extraordinary semi-final match at San Siro. The thrilling contest featured remarkable comebacks from both sides, with substitute Davide Frattesi scoring the decisive goal in the 99th minute of extra time. This victory sends Inter to their second Champions League final in three years, where they will face either Arsenal or Paris Saint-Germain.",
  "did_you_know": "The epic two-legged semifinal between Inter Milan and Barcelona produced a total of 13 goals, making it one of the highest-scoring Champions League semifinals in history.",
  "talking_points": [
    "Dramatic comebacks: Both legs ended in 3-3 draws before Inter secured victory with Frattesi's extra-time winner in the second leg.",
    "Young talent shines: Barcelona's teenage sensation Lamine Yamal dazzled throughout the tie but was denied a late equalizer by a crucial save from Inter goalkeeper Yann Sommer.",
    "Historic achievement: Inter manager Simone Inzaghi praised his team for eliminating \"the best two sides in Europe\" after previously defeating Bayern Munich in the quarter-finals.",
    "Fan celebration: Real Madrid supporters showed their appreciation for Inter's victory over their domestic rivals by bringing Inter scarves and banners to Madrid's training ground.",
    "Tactical battle: Despite Barcelona's possession advantage, Inter's clinical finishing and resilient defending proved decisive in the semi-final encounter."
  ],
  "quote": "I'm very proud to be the coach of these guys. They gave everything on the pitch and used energy they didn't have. But I want to congratulate Barcelona as well, they are a great team. De Jong impressed me.",
  "quote_author": "Simone Inzaghi, Inter Milan manager",
  "quote_source_url": "https://www.reddit.com/r/soccer/comments/1kgjjj9/simone_inzaghi_im_very_proud_to_be_the_coach_of/",
  "quote_source_domain": "reddit.com",
  "location": "Milan, Italy",
  "perspectives": [
    {
      "text": "Simone Inzaghi: Believes Inter defeated \"the best two sides in Europe\" on their way to the final, highlighting his team's extraordinary achievement.",
      "sources": [
        {
          "name": "The Guardian",
          "url": "https://www.theguardian.com/football/2025/may/07/simone-inzaghi-inter-champions-league-barcelona-reaction"
        }
      ]
    },
    {
      "text": "Thierry Henry: Described the semifinal as \"why we love football,\" celebrating the breathtaking nature of a tie that produced 13 goals across two legs.",
      "sources": [
        {
          "name": "CBS Sports",
          "url": "https://www.cbssports.com/soccer/news/this-is-why-we-love-football-thierry-henry-breaks-down-inter-and-barcelonas-breathtaking-ucl-semis/"
        }
      ]
    },
    {
      "text": "Spanish media: Labeled the result as \"Goodbye epic!\" in their newspapers, expressing disappointment at Barcelona's exit despite the entertaining nature of the contest.",
      "sources": [
        {
          "name": "The Independent",
          "url": "https://www.independent.co.uk/sport/football/inter-barcelona-champions-league-newspapers-goals-b2746245.html"
        }
      ]
    },
    {
      "text": "Yann Sommer: Described his crucial late save against Lamine Yamal as \"special\" and instrumental in helping Inter reach the final.",
      "sources": [
        {
          "name": "ESPN",
          "url": "https://www.espn.com/soccer/story/_/id/45029381/inter-milan-yann-sommer-makes-special-save-lamine-yamal"
        }
      ]
    }
  ],
  "emoji": "⚽",
  "geopolitical_context": "",
  "historical_background": "This marks Inter Milan's second Champions League final appearance in three seasons, having previously reached the final in 2023 where they lost to Manchester City. The Italian club has won the European Cup/Champions League three times in their history, with their last triumph coming in 2010 under José Mourinho.",
  "international_reactions": "",
  "humanitarian_impact": "",
  "economic_implications": "",
  "timeline": [
    "First leg:: Barcelona and Inter draw 3-3 in Spain",
    "May 6, 2025:: Inter defeat Barcelona 4-3 after extra time in the second leg",
    "21st minute:: Lautaro Martínez opens scoring for Inter",
    "45th minute:: Calhanoglu doubles Inter's lead from the penalty spot",
    "87th minute:: Raphinha gives Barcelona 3-2 lead",
    "90+3 minute:: Acerbi equalizes to force extra time",
    "99th minute:: Frattesi scores winner to send Inter to final"
  ],
  "future_outlook": "",
  "key_players": [],
  "technical_details": "",
  "business_angle_text": "",
  "business_angle_points": [],
  "user_action_items": "",
  "scientific_significance": [],
  "travel_advisory": [],
  "destination_highlights": "",
  "culinary_significance": "",
  "performance_statistics": [
    "Lautaro Martínez scored Inter's opening goal, continuing his excellent form in this Champions League campaign.",
    "Francesco Acerbi scored a dramatic 93rd minute equalizer to force extra time after Barcelona had taken a 3-2 lead.",
    "Davide Frattesi came off the bench to score the decisive goal in the 99th minute of extra time.",
    "Yann Sommer made a crucial save to deny Lamine Yamal what would have been a dramatic late equalizer.",
    "Barcelona's Raphinha scored in the 87th minute to give his team a temporary 3-2 lead before Acerbi's equalizer."
  ],
  "league_standings": "Inter Milan will now advance to the Champions League final where they will face either Arsenal or Paris Saint-Germain. The final represents a chance for Inter to claim their fourth European Cup/Champions League title in club history, while Barcelona's elimination means they will have to wait at least another season for a chance at European glory.",
  "diy_tips": "",
  "design_principles": "",
  "user_experience_impact": "",
  "gameplay_mechanics": [],
  "industry_impact": [
    "Broadcasting success: The thrilling nature of the tie delivered exceptional viewership numbers, showcasing the enduring global appeal of the Champions League.",
    "Club finances: Inter Milan's progression to another Champions League final will significantly boost their revenue through prize money, sponsorships, and merchandise sales.",
    "Tournament prestige: The extraordinary quality and drama of the semifinal further cements the Champions League's reputation as the premier club competition in world football."
  ],
  "technical_specifications": "",
  "articles": [
    {
      "title": "Video: Real Madrid fans thank Inter for eliminating Barcelona",
      "link": "https://football-italia.net/real-madrid-fans-inter-barcelona-eliminate/",
      "domain": "football-italia.net",
      "date": "2025-05-07T11:45:00+00:00",
      "image": "https://kagiproxy.com/img/lT0AjrqMdmEOHzTUCFcWCBp8iJrS1Yfc_GiVxmDqgXMv8x6_5WSiGLF1nJa5_6NTt5tWcIUjq2cvHNNERIr09NBckOEKcCOK8S_OZxNoB-f3zlnmz6xjVnz0DXPIc7_YyYM3rsR6uT6tgOyEknysp7cfr2o",
      "image_caption": "MILAN, ITALY - MAY 06: Lamine Yamal of FC Barcelona is challenged by Federico Dimarco of FC Internazionale during the UEFA Champions League 2024/25 Semi Final Second Leg match between FC Internazionale Milano and FC Barcelona at Giuseppe Meazza Stadium on May 06, 2025 in Milan, Italy. (Photo by Dan Mullan/Getty Images)"
    },
    {
      "title": "Inter Milan and Barcelona produced a legendary semi-final – but where does it rank in Champions League history?",
      "link": "https://www.independent.co.uk/sport/football/inter-barcelona-champions-league-semi-finals-top-10-b2746346.html",
      "domain": "independent.co.uk",
      "date": "2025-05-07T11:15:35+00:00",
      "image": "https://kagiproxy.com/img/MOl5yGo6adhaJgdTCsz5DH-byC8ypu-TmtEnqzelmrUpPmlYFNeEXloyXoY_47CzE90SxrS1PjJiIAYt4yInYq43CQTPiYYWwjU--pWK5lrIGMEhaCb31GBZDFVZxBRBUOWmKMPKsUq2CjPiRZIXP5O_pVGTp2dh8gfUk9WGPfAaYiLOQZLEUNIwqiFyKmB-2Rc-rCvs7g2DOD6PqC318C7NAjRVdUVHx5fzqEFoKVfWrNRT2hlQbYOixJpDtWGBEGMZlimZbGA",
      "image_caption": "Davide Frattesi of Inter Milan celebrates scoring his team's fourth goal - (Getty Images)"
    },
    {
      "title": "Champions League semifinal: Inter Milan beats Barcelona 4-3 after extra time to reach final",
      "link": "https://www.thehindu.com/sport/football/champions-league-semifinal-inter-milan-beats-barcelona-4-3-after-extra-time-to-reach-final/article69548433.ece",
      "domain": "thehindu.com",
      "date": "2025-05-07T10:32:49+00:00",
      "image": "",
      "image_caption": ""
    },
    {
      "title": "Barcelona, Inter bless us with Champions League classic as Yamal, Dumfries, Sommer all shine",
      "link": "https://www.football365.com/news/opinion-barcelona-inter-champions-league-classic-yamal-dumfries-sommer-dazzle",
      "domain": "football365.com",
      "date": "2025-05-06T20:56:36+00:00",
      "image": "",
      "image_caption": ""
    },
    {
      "title": "Inter aim for Champions League glory: Three reasons why they are better prepared this time around",
      "link": "\n                                                https://www.cbssports.com/soccer/news/inter-aim-for-champions-league-glory-three-reasons-why-they-are-better-prepared-this-time-around/\n                    ",
      "domain": "cbssports.com",
      "date": "2025-05-07T02:31:49+00:00",
      "image": "",
      "image_caption": ""
    },
    {
      "title": "'This is why we love football': Thierry Henry breaks down Inter and Barcelona's breathtaking UCL semis",
      "link": "\n                                                https://www.cbssports.com/soccer/news/this-is-why-we-love-football-thierry-henry-breaks-down-inter-and-barcelonas-breathtaking-ucl-semis/\n                    ",
      "domain": "cbssports.com",
      "date": "2025-05-07T00:29:06+00:00",
      "image": "",
      "image_caption": ""
    },
    {
      "title": "Top 10 moments from Inter's epic Champions League win over Barca: Francesco Acerbi's goal, Lamine Yamal stars",
      "link": "\n                                                https://www.cbssports.com/soccer/news/top-10-moments-from-inters-epic-champions-league-win-over-barca-francesco-acerbis-goal-lamine-yamal-stars/\n                    ",
      "domain": "cbssports.com",
      "date": "2025-05-07T00:00:26+00:00",
      "image": "",
      "image_caption": ""
    }
  ],
  "domains": [
    {
      "name": "football365.com",
      "favicon": "https://kagiproxy.com/img/8mTaurOCouu3Pwo9vD004esJbEfwe7WgZQSmI7ekD4ddO5HUryqvO89TNn6G0PS9MkBX5HYFtWIdiB4LSXeMwjTpyaxu2ackTvBRREDYdapt33_EYg"
    },
    {
      "name": "cbssports.com",
      "favicon": "https://kagiproxy.com/img/FdhpdY73q99-IUdYg-Q18BG4YAeKBtJRBjNaljCeWqxHBTTxV7to4JlMRmkFs3zjvegmoO9SF4oQxBv9X-fwgC09WhvUnWNj0vLrL9krykyl0hU"
    },
    {
      "name": "thehindu.com",
      "favicon": "https://kagiproxy.com/img/P2WiTEODt09566ttAkk5qDmw1-Xio8fAHrlHT-WQUFBKOgWwukSj4MCLvvA56FTG3CQiPHrlzm0gjzAbMCRWQkMru4Cbea309nfuQo25Qkj18w"
    },
    {
      "name": "football-italia.net",
      "favicon": "https://kagiproxy.com/img/2mZPiC_57-o_GlsxOVR01uka6_BV859ytC3OO2UtNxrWGfdi6YMXNwfnm3yoVi-EipnHLCSPQg997fGKPUbhPTilT24xZTMp1RXoJz8MTlpDtx8_Xt60Suo"
    },
    {
      "name": "independent.co.uk",
      "favicon": "https://kagiproxy.com/img/QIrQUt6IUUzH3_ePkJeqidk19wOKwhRtSF4fOcX11L-rG0h33fk9L3qDL-AzBhBSLTrkq0ZQMJDabmmC-k0lIelHGPUte3ttGUiHukAXdcxMTCdhoLNQ"
    }
  ]
}
''';
