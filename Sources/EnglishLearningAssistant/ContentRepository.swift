import Foundation

final class ContentRepository: @unchecked Sendable {
    static let shared = ContentRepository()

    let vocabulary: [VocabularyEntry]
    let grammar: [GrammarEntry]

    private let vocabularyByID: [String: VocabularyEntry]
    private let grammarByID: [String: GrammarEntry]

    private init() {
        let bases = Self.parseBaseWords()
        vocabulary = bases.flatMap(Self.makeVocabularyFamily)
        grammar = Self.makeGrammarEntries()
        vocabularyByID = Dictionary(uniqueKeysWithValues: vocabulary.map { ($0.id, $0) })
        grammarByID = Dictionary(uniqueKeysWithValues: grammar.map { ($0.id, $0) })
    }

    func vocabulary(id: String) -> VocabularyEntry? {
        vocabularyByID[id]
    }

    func grammar(id: String) -> GrammarEntry? {
        grammarByID[id]
    }

    private struct BaseWord {
        let word: String
        let phonetic: String
        let partOfSpeech: String
        let meaning: String
    }

    private struct DailyLifeDetail {
        let example: String
        let translation: String
        let phrases: [RelatedPhrase]
    }

    private static func parseBaseWords() -> [BaseWord] {
        baseWordData
            .split(separator: "\n")
            .compactMap { line in
                let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
                guard fields.count == 4 else { return nil }
                return BaseWord(
                    word: fields[0],
                    phonetic: fields[1],
                    partOfSpeech: fields[2],
                    meaning: fields[3]
                )
            }
    }

    private static func makeVocabularyFamily(from base: BaseWord) -> [VocabularyEntry] {
        let slug = base.word.lowercased().replacingOccurrences(of: " ", with: "-")
        guard let detail = dailyLifeDetails[base.word.lowercased()] else {
            preconditionFailure("Missing daily-life content for \(base.word)")
        }
        let phrases = detail.phrases

        let main = VocabularyEntry(
            id: "v-\(slug)",
            word: base.word,
            phonetic: base.phonetic,
            partOfSpeech: base.partOfSpeech,
            meaning: base.meaning,
            example: detail.example,
            translation: detail.translation,
            phrases: phrases,
            usageNotes: [
                UsageNote(
                    category: "核心用法",
                    explanation: usageExplanation(for: base),
                    pattern: usagePattern(for: base),
                    example: detail.example
                )
            ]
        )

        let phraseEntries = phrases.prefix(2).enumerated().map { index, phrase in
            VocabularyEntry(
                id: "v-\(slug)-phrase-\(index + 1)",
                word: phrase.text,
                phonetic: "短语",
                partOfSpeech: "常用搭配",
                meaning: phrase.meaning,
                example: phrase.example,
                translation: phrase.translation,
                phrases: [
                    RelatedPhrase(
                        text: base.word,
                        meaning: base.meaning,
                        example: detail.example,
                        translation: detail.translation
                    ),
                    phrases[index == 0 ? 1 : 0]
                ],
                usageNotes: [
                    UsageNote(
                        category: "搭配记忆",
                        explanation: "把这个搭配作为一个整体记忆，在日常交流中会更自然。",
                        pattern: phrase.text,
                        example: phrase.example
                    )
                ]
            )
        }

        return [main] + phraseEntries
    }

    private static let dailyLifeDetails: [String: DailyLifeDetail] = {
        Dictionary(
            uniqueKeysWithValues: dailyLifeDetailData
                .split(separator: "\n")
                .map { line in
                    let fields = line
                        .split(separator: "|", omittingEmptySubsequences: false)
                        .map(String.init)
                    precondition(fields.count == 11, "Invalid daily-life content: \(line)")
                    return (
                        fields[0].lowercased(),
                        DailyLifeDetail(
                            example: fields[1],
                            translation: fields[2],
                            phrases: [
                                RelatedPhrase(
                                    text: fields[3],
                                    meaning: fields[4],
                                    example: fields[5],
                                    translation: fields[6]
                                ),
                                RelatedPhrase(
                                    text: fields[7],
                                    meaning: fields[8],
                                    example: fields[9],
                                    translation: fields[10]
                                )
                            ]
                        )
                    )
                }
        )
    }()

    private static func usageExplanation(for base: BaseWord) -> String {
        if base.partOfSpeech.contains("感叹词") {
            return "可单独用于打招呼，也可放在称呼前后。语气自然友好，适合见面或接电话时使用。"
        }
        if base.partOfSpeech.contains("副词") {
            return "常放在请求句中让语气更礼貌，也可以单独用于回应。注意根据场景配合自然语调。"
        }
        if base.partOfSpeech.contains("动词") {
            return "作动词使用。一般现在时中，主语为 he、she 或 it 时通常要注意第三人称单数变化。"
        }
        if base.partOfSpeech.contains("形容词") {
            return "可放在 be、feel、seem 等系动词之后，也可以放在名词前作修饰语。"
        }
        return "作名词使用时注意可数性；表达单数可数事物时通常需要 a、an 或其他限定词。"
    }

    private static func usagePattern(for base: BaseWord) -> String {
        if base.partOfSpeech.contains("感叹词") {
            return "\(base.word)! / \(base.word) + 称呼"
        }
        if base.partOfSpeech.contains("副词") {
            return "\(base.word) + 动词原形 / 请求内容"
        }
        if base.partOfSpeech.contains("动词") {
            return "主语 + \(base.word) / \(base.word)s + 其他"
        }
        if base.partOfSpeech.contains("形容词") {
            return "主语 + be / feel + \(base.word)"
        }
        return "限定词 + \(base.word)"
    }

    private static let dailyLifeDetailData = """
    hello|Hello, is anyone sitting here?|你好，这里有人坐吗？|say hello|打招呼|Go over and say hello.|过去打个招呼吧。|hello again|又见面了|Hello again. How have you been?|又见面了，你最近怎么样？
    thanks|Thanks for picking me up.|谢谢你来接我。|thanks for your help|谢谢你的帮助|Thanks for your help today.|谢谢你今天的帮助。|many thanks|非常感谢|Many thanks for the quick reply.|非常感谢你的快速回复。
    sorry|Sorry, I took the wrong bag.|抱歉，我拿错包了。|sorry about that|对此很抱歉|I forgot to call. Sorry about that.|我忘记打电话了，对此很抱歉。|sorry to bother you|抱歉打扰你|Sorry to bother you, but is this seat free?|抱歉打扰一下，这个座位有人吗？
    please|Please leave the package by the door.|请把包裹放在门边。|yes, please|好的，请给我|Would you like some tea? Yes, please.|你想喝茶吗？好的，请给我一些。|please wait|请稍等|Please wait here for a moment.|请在这里稍等一下。
    friend|A friend is coming over for dinner.|一个朋友要来家里吃晚饭。|close friend|亲密朋友|She is a close friend from school.|她是我上学时的好朋友。|make friends|交朋友|It takes time to make friends in a new city.|在新城市交朋友需要时间。
    family|My family usually eats together on Sundays.|我家通常周日一起吃饭。|family dinner|家庭聚餐|We are having a family dinner tonight.|我们今晚要家庭聚餐。|family member|家庭成员|Every family member has a key.|每个家庭成员都有一把钥匙。
    name|Could you spell your name for me?|你能为我拼一下你的名字吗？|first name|名|Please write your first name here.|请在这里写下你的名。|last name|姓|Her last name is Chen.|她姓陈。
    time|What time should we leave?|我们应该几点出发？|on time|准时|The bus arrived on time.|公交车准时到了。|free time|空闲时间|I listen to podcasts in my free time.|我空闲时听播客。
    day|I had a long day, so I am going to bed early.|我今天很累，所以准备早点睡。|all day|一整天|It rained all day yesterday.|昨天一整天都在下雨。|day off|休息日|Friday is my day off.|星期五是我的休息日。
    morning|I usually make coffee first thing in the morning.|我早上起来通常先煮咖啡。|this morning|今天早上|I missed your call this morning.|我今天早上没接到你的电话。|tomorrow morning|明天早上|Let's go shopping tomorrow morning.|我们明天早上去购物吧。
    evening|We took a walk after dinner this evening.|我们今晚饭后散了步。|in the evening|在晚上|I prefer to exercise in the evening.|我更喜欢晚上锻炼。|evening plans|晚上的安排|Do you have any evening plans?|你晚上有什么安排吗？
    home|I will be home around seven.|我大约七点到家。|go home|回家|I'm tired. Let's go home.|我累了，我们回家吧。|at home|在家|I left my wallet at home.|我把钱包忘在家里了。
    room|This room gets a lot of sunlight.|这个房间阳光很充足。|living room|客厅|The kids are playing in the living room.|孩子们正在客厅玩。|room key|房卡|I can't find my room key.|我找不到房卡了。
    food|The food here is simple but delicious.|这里的食物简单但很好吃。|order food|点餐|Let's order food instead of cooking.|我们别做饭了，点餐吧。|food delivery|外卖|The food delivery will arrive in ten minutes.|外卖十分钟后送到。
    water|Could I have a glass of water?|可以给我一杯水吗？|bottled water|瓶装水|Do you sell bottled water?|你们卖瓶装水吗？|hot water|热水|I need some hot water for tea.|我需要一些热水泡茶。
    coffee|I usually get a coffee on my way to work.|我上班路上通常会买杯咖啡。|black coffee|黑咖啡|He drinks black coffee without sugar.|他喝不加糖的黑咖啡。|coffee shop|咖啡店|There is a quiet coffee shop downstairs.|楼下有一家安静的咖啡店。
    breakfast|I skipped breakfast because I woke up late.|我起晚了，所以没吃早餐。|have breakfast|吃早餐|We usually have breakfast at home.|我们通常在家吃早餐。|breakfast menu|早餐菜单|Could I see the breakfast menu?|可以给我看看早餐菜单吗？
    lunch|Let's meet for lunch near your office.|我们在你办公室附近一起吃午饭吧。|lunch break|午休|I need to run an errand during my lunch break.|我午休时需要办点事。|pack lunch|带午饭|I pack lunch when I have time.|有时间时我会自己带午饭。
    dinner|What would you like for dinner?|晚饭你想吃什么？|cook dinner|做晚饭|I'll cook dinner tonight.|今晚我来做饭。|after dinner|晚饭后|Let's take a walk after dinner.|我们晚饭后散步吧。
    restaurant|This restaurant is busy on weekends.|这家餐厅周末很忙。|book a restaurant|预订餐厅|I booked a restaurant for seven.|我订了七点的餐厅。|restaurant bill|餐厅账单|Could we have the restaurant bill, please?|麻烦给我们账单。
    shop|The shop closes at nine.|这家店九点关门。|go shopping|去购物|Do you want to go shopping after lunch?|午饭后你想去购物吗？|corner shop|街角小店|I bought milk at the corner shop.|我在街角小店买了牛奶。
    money|I don't have enough cash with me.|我身上没有足够的现金。|save money|省钱|Cooking at home helps us save money.|在家做饭能帮我们省钱。|spend money|花钱|I don't want to spend money on another bag.|我不想再花钱买包了。
    price|The price includes delivery.|这个价格包含配送费。|check the price|查看价格|Let me check the price online.|我上网查一下价格。|same price|相同价格|Both sizes are the same price.|两个尺寸价格相同。
    ticket|I bought the train ticket on my phone.|我用手机买了火车票。|return ticket|往返票|I'd like a return ticket to Boston.|我想买一张去波士顿的往返票。|ticket machine|售票机|The ticket machine only accepts cards.|这台售票机只接受刷卡。
    bus|The next bus comes in five minutes.|下一班公交车五分钟后到。|bus stop|公交站|I'll meet you at the bus stop.|我在公交站和你碰面。|take the bus|乘公交车|I take the bus when it rains.|下雨时我坐公交车。
    train|Our train leaves from platform six.|我们的火车从六号站台出发。|catch the train|赶上火车|We need to hurry to catch the train.|我们得快点才能赶上火车。|train station|火车站|Is the train station within walking distance?|火车站走路能到吗？
    airport|We should get to the airport two hours early.|我们应该提前两小时到机场。|airport shuttle|机场班车|The airport shuttle stops outside the hotel.|机场班车停在酒店外。|airport security|机场安检|The line at airport security is long.|机场安检队伍很长。
    hotel|The hotel can store our bags after checkout.|退房后酒店可以寄存行李。|hotel room|酒店房间|Our hotel room is on the eighth floor.|我们的酒店房间在八楼。|hotel reservation|酒店预订|I'd like to confirm my hotel reservation.|我想确认一下酒店预订。
    street|There is a pharmacy across the street.|街对面有一家药店。|cross the street|过马路|Use the light when you cross the street.|过马路时请走红绿灯。|main street|主街|The bank is on the main street.|银行在主街上。
    place|This is a nice place for a quiet lunch.|这是个安静吃午饭的好地方。|meeting place|见面地点|Let's choose an easy meeting place.|我们选一个好找的见面地点吧。|take place|发生|The market takes place every Saturday.|集市每周六举行。
    work|I finish work at six today.|我今天六点下班。|go to work|去上班|I usually walk to work.|我通常走路上班。|after work|下班后|Let's get groceries after work.|我们下班后去买菜吧。
    office|I left my charger at the office.|我把充电器落在办公室了。|office building|办公楼|The office building is next to the bank.|办公楼在银行旁边。|office hours|办公时间|The clinic's office hours end at five.|诊所的办公时间到五点结束。
    meeting|Can we move the meeting to Friday?|我们能把会议改到周五吗？|have a meeting|开会|I have a meeting at ten.|我十点有个会。|meeting room|会议室|The meeting room is on the second floor.|会议室在二楼。
    question|I have a question about the bill.|我对账单有个问题。|ask a question|提问|Feel free to ask a question.|有问题尽管问。|quick question|一个小问题|Can I ask you a quick question?|我能问你一个小问题吗？
    answer|I don't know the answer yet.|我还不知道答案。|answer the phone|接电话|Could you answer the phone?|你能接一下电话吗？|simple answer|简单回答|There isn't a simple answer to that.|那个问题没有简单答案。
    idea|That's a good idea for the weekend.|这是个不错的周末安排。|have an idea|有个主意|I have an idea for dinner.|我对晚饭有个主意。|better idea|更好的主意|Do you have a better idea?|你有更好的主意吗？
    problem|The only problem is that the store is closed.|唯一的问题是商店关门了。|no problem|没问题|No problem. I can wait.|没问题，我可以等。|solve a problem|解决问题|Restarting the phone solved the problem.|重启手机解决了问题。
    help|Could you help me carry this box?|你能帮我搬这个箱子吗？|ask for help|寻求帮助|Don't be afraid to ask for help.|别害怕寻求帮助。|need help|需要帮助|Let me know if you need help.|需要帮助就告诉我。
    phone|My phone is almost out of battery.|我的手机快没电了。|phone number|电话号码|Can I have your phone number?|能告诉我你的电话号码吗？|phone charger|手机充电器|Did you bring a phone charger?|你带手机充电器了吗？
    message|I sent you a message this morning.|我今天早上给你发了消息。|text message|短信|I got a text message from the delivery driver.|我收到了配送司机的短信。|leave a message|留言|Please leave a message after the tone.|请在提示音后留言。
    weather|The weather should be warmer tomorrow.|明天天气应该会暖和些。|weather forecast|天气预报|The weather forecast says it will rain.|天气预报说会下雨。|bad weather|恶劣天气|The game was canceled because of bad weather.|比赛因天气恶劣取消了。
    weekend|We're visiting my parents this weekend.|这个周末我们要去看父母。|last weekend|上周末|We stayed home last weekend.|我们上周末待在家里。|weekend plans|周末计划|What are your weekend plans?|你周末有什么计划？
    holiday|The store is closed for the holiday.|这家店因节假日休息。|public holiday|公共假日|Monday is a public holiday.|星期一是公共假日。|on holiday|在度假|She's on holiday with her family.|她正和家人度假。
    language|The app lets you change the language.|这个应用可以更改语言。|body language|肢体语言|His body language showed that he was nervous.|他的肢体语言表明他很紧张。|language class|语言课|I go to a language class on Tuesdays.|我每周二上语言课。
    english|Could you say that again in English?|你能用英语再说一遍吗？|speak English|说英语|Do you speak English?|你会说英语吗？|English class|英语课|My English class starts at seven.|我的英语课七点开始。
    music|I listen to music while I cook.|我做饭时会听音乐。|live music|现场音乐|The cafe has live music on Fridays.|这家咖啡馆周五有现场音乐。|turn down the music|把音乐调小|Could you turn down the music a little?|你能把音乐调小一点吗？
    movie|We watched a movie at home last night.|我们昨晚在家看了一部电影。|movie theater|电影院|There's a movie theater near the station.|车站附近有家电影院。|watch a movie|看电影|Do you want to watch a movie tonight?|你今晚想看电影吗？
    book|I borrowed this book from the library.|我从图书馆借了这本书。|book a table|订桌|I'd like to book a table for two.|我想订一张两人桌。|read a book|读书|I read a book before bed.|我睡前会读书。
    story|She told us a funny story over dinner.|她吃饭时给我们讲了个有趣的故事。|true story|真实故事|Is that a true story?|那是真实的故事吗？|tell a story|讲故事|Grandpa likes to tell a story before bedtime.|爷爷喜欢睡前讲故事。
    plan|Our plan is to leave before traffic gets bad.|我们的计划是在堵车前出发。|make a plan|制定计划|Let's make a plan for Saturday.|我们计划一下周六的安排吧。|change of plan|计划有变|There's been a change of plan.|计划有变。
    go|I need to go to the grocery store after work.|我下班后得去杂货店。|go out|外出|Do you want to go out for dinner?|你想出去吃晚饭吗？|go back|回去|I need to go back for my keys.|我得回去拿钥匙。
    come|Can you come over after dinner?|你晚饭后能过来吗？|come in|进来|Come in and take off your coat.|进来把外套脱了吧。|come back|回来|What time will you come back?|你几点回来？
    eat|Let's eat before the food gets cold.|趁饭还没凉，我们吃吧。|eat out|在外吃饭|We eat out once a week.|我们每周在外吃一次饭。|eat breakfast|吃早餐|I rarely eat breakfast this early.|我很少这么早吃早餐。
    drink|Remember to drink enough water today.|记得今天多喝水。|drink coffee|喝咖啡|I don't drink coffee after four.|我四点后不喝咖啡。|something to drink|喝的东西|Would you like something to drink?|你想喝点什么吗？
    buy|I need to buy some milk on the way home.|我回家路上需要买些牛奶。|buy online|网购|I usually buy household items online.|我通常在网上买家居用品。|buy a ticket|买票|Can we buy a ticket at the station?|我们能在车站买票吗？
    pay|Can I pay by card?|我可以刷卡吗？|pay the bill|付账|I'll pay the bill this time.|这次我来付账。|pay in cash|付现金|Do I need to pay in cash?|我需要付现金吗？
    find|I can't find my glasses anywhere.|我到处都找不到眼镜。|find out|查明|I'll find out when the store opens.|我来查一下商店几点开门。|find a place|找个地方|Let's find a place to sit.|我们找个地方坐吧。
    ask|I'll ask the driver where to get off.|我会问司机在哪里下车。|ask for directions|问路|We stopped to ask for directions.|我们停下来问路。|ask someone|询问某人|You can ask someone at the front desk.|你可以问前台的人。
    tell|Please tell me when you're ready.|你准备好时请告诉我。|tell the truth|说实话|Just tell me the truth.|直接告诉我实话吧。|tell someone about|告诉某人某事|Did you tell your family about the trip?|你告诉家人这次旅行了吗？
    speak|Could you speak a little more slowly?|你能说慢一点吗？|speak to|和某人谈话|I'd like to speak to the manager.|我想和经理谈谈。|speak up|大声一点说|Could you speak up, please?|你能大声一点吗？
    listen|Listen carefully for your stop.|仔细听报站，别坐过站。|listen to music|听音乐|I listen to music on the train.|我在火车上听音乐。|listen to someone|听某人说|Please listen to me for a minute.|请听我说一分钟。
    read|I read the news while eating breakfast.|我吃早餐时看新闻。|read aloud|大声朗读|Could you read this sentence aloud?|你能大声读这个句子吗？|read a message|读消息|I read your message but forgot to reply.|我看了你的消息，但忘记回复了。
    write|Please write the address on the package.|请把地址写在包裹上。|write down|写下来|Write down the door code.|把门禁密码写下来。|write back|回复|I'll write back after dinner.|我晚饭后回复。
    learn|I'm learning how to cook a few simple meals.|我正在学做几道简单的饭菜。|learn English|学英语|She learns English on her commute.|她通勤时学英语。|learn from|向……学习|I learned this recipe from my mother.|这道菜是我跟妈妈学的。
    remember|Remember to lock the door when you leave.|离开时记得锁门。|remember to do|记得做某事|Remember to bring an umbrella.|记得带伞。|remember someone's name|记住某人的名字|I'm not good at remembering people's names.|我不太擅长记人名。
    understand|I understand most of the menu now.|我现在能看懂菜单上的大部分内容了。|understand the question|理解问题|I don't understand the question.|我不明白这个问题。|easy to understand|容易理解|Her instructions were easy to understand.|她的说明很容易理解。
    know|Do you know a good place for lunch?|你知道适合吃午饭的好地方吗？|know how to|知道如何|Do you know how to use this machine?|你知道怎么用这台机器吗？|let someone know|告知某人|Let me know when you get home.|到家后告诉我。
    think|I think we should leave a little earlier.|我觉得我们应该早一点出发。|think about|考虑|I'll think about it tonight.|我今晚会考虑一下。|think so|这样认为|I think so, but I'm not completely sure.|我觉得是，但不完全确定。
    want|I want something warm to eat.|我想吃点热的东西。|want to go|想去|Do you want to go with us?|你想和我们一起去吗？|want some|想要一些|Do you want some coffee?|你想喝点咖啡吗？
    need|We need more eggs for breakfast.|我们早餐还需要一些鸡蛋。|need to do|需要做某事|I need to charge my phone.|我需要给手机充电。|need help|需要帮助|Do you need help with those bags?|这些包需要我帮你拿吗？
    like|I like this neighborhood because it's quiet.|我喜欢这个社区，因为很安静。|would like|想要|I'd like a table by the window.|我想要一张靠窗的桌子。|feel like|想做某事|I feel like staying home tonight.|我今晚想待在家里。
    love|I love having breakfast outside in summer.|我喜欢夏天在户外吃早餐。|love to do|喜欢做某事|My kids love to play in the park.|我的孩子喜欢在公园玩。|would love to|很愿意|I'd love to come to dinner.|我很愿意来吃晚饭。
    call|I'll call you when I arrive.|我到后给你打电话。|call back|回电话|Can I call you back in ten minutes?|我十分钟后回你电话可以吗？|call a taxi|叫出租车|Let's call a taxi from the hotel.|我们从酒店叫辆出租车吧。
    wait|I'll wait for you outside the station.|我会在车站外等你。|wait a minute|等一下|Wait a minute. I forgot my wallet.|等一下，我忘带钱包了。|wait in line|排队等候|We waited in line for twenty minutes.|我们排了二十分钟队。
    start|The movie starts at eight.|电影八点开始。|start the car|发动汽车|The car won't start this morning.|车今天早上发动不了。|start with|从……开始|Let's start with something easy.|我们从简单的开始吧。
    finish|I'll finish the dishes before I go out.|我出门前会洗完碗。|finish work|下班|What time do you finish work?|你几点下班？|finish eating|吃完|Call me when you finish eating.|吃完后给我打电话。
    try|Try this soup while it's hot.|趁热尝尝这个汤。|try on|试穿|Can I try on this jacket?|我可以试穿这件夹克吗？|try again|再试一次|The code didn't work, so try again.|密码没用，再试一次。
    use|Can I use your charger for a minute?|我能用一下你的充电器吗？|use the bathroom|使用卫生间|May I use the bathroom?|我可以用一下卫生间吗？|easy to use|容易使用|This coffee machine is easy to use.|这台咖啡机很容易使用。
    make|I'll make some tea for everyone.|我给大家泡些茶。|make dinner|做晚饭|We can make dinner together.|我们可以一起做晚饭。|make sure|确保|Make sure the door is locked.|确保门锁好了。
    take|Take an umbrella in case it rains.|带把伞，以防下雨。|take a break|休息一下|Let's take a short break.|我们短暂休息一下吧。|take the bus|乘公交车|We can take the bus downtown.|我们可以坐公交车去市中心。
    give|Could you give me a hand with this table?|你能帮我搬一下这张桌子吗？|give someone a call|给某人打电话|Give me a call when you're free.|有空时给我打电话。|give directions|指路|A local gave us directions to the station.|一位当地人给我们指了去车站的路。
    happy|I'm happy we found a table outside.|我很高兴我们找到了户外座位。|happy with|对……满意|Are you happy with your new phone?|你对新手机满意吗？|happy to help|很乐意帮忙|I'm happy to help if you need anything.|需要什么我很乐意帮忙。
    busy|The grocery store is usually busy after work.|杂货店下班后通常很忙。|busy day|忙碌的一天|I've had a busy day.|我今天很忙。|busy with|忙于|She's busy with dinner right now.|她现在正忙着做晚饭。
    tired|I'm too tired to cook tonight.|我今晚太累了，不想做饭。|feel tired|感到疲惫|I always feel tired after a long flight.|长途飞行后我总觉得累。|tired of|厌倦|I'm tired of eating the same lunch.|我吃腻了同样的午饭。
    ready|I'm ready to leave whenever you are.|你什么时候准备好，我就什么时候出发。|get ready|做准备|I need ten minutes to get ready.|我需要十分钟准备。|ready for|为……做好准备|Are you ready for dinner?|你准备好吃晚饭了吗？
    easy|This recipe is easy to follow.|这个食谱很容易照着做。|take it easy|放轻松|Take it easy this weekend.|这个周末放轻松。|easy to find|容易找到|The hotel is easy to find from the station.|从车站很容易找到酒店。
    difficult|It's difficult to hear you in this noisy cafe.|这家咖啡馆太吵，很难听清你说话。|difficult to do|很难做某事|This jar is difficult to open.|这个罐子很难打开。|difficult decision|艰难的决定|Moving was a difficult decision.|搬家是个艰难的决定。
    important|It's important to keep your receipt.|保留收据很重要。|important to|对……重要|Sleep is important to your health.|睡眠对健康很重要。|important thing|重要的事|The important thing is that everyone is safe.|重要的是大家都安全。
    interesting|We found an interesting market near the river.|我们在河边发现了一个有趣的集市。|interesting idea|有趣的想法|That's an interesting idea for dinner.|这是个有趣的晚饭主意。|sound interesting|听起来有趣|The new cafe sounds interesting.|那家新咖啡馆听起来不错。
    good|This soup is really good.|这个汤真的很好喝。|good at|擅长|My brother is good at fixing things.|我哥哥擅长修东西。|good for|对……有益|Walking is good for your health.|走路对健康有益。
    bad|The traffic is bad this morning.|今天早上交通很糟。|bad weather|坏天气|We stayed inside because of the bad weather.|因为天气不好，我们待在室内。|feel bad|感到不舒服或抱歉|I feel bad about missing your call.|没接到你的电话，我感到很抱歉。
    new|I bought a new kettle for the kitchen.|我给厨房买了一个新水壶。|brand new|全新的|The washing machine is brand new.|这台洗衣机是全新的。|new to|刚接触|I'm new to this neighborhood.|我刚搬到这个社区。
    old|This old chair is still comfortable.|这把旧椅子仍然很舒服。|years old|……岁|My phone is three years old.|我的手机用了三年了。|old friend|老朋友|I had lunch with an old friend.|我和一位老朋友吃了午饭。
    big|We need a bigger table for dinner.|我们晚饭需要一张更大的桌子。|big enough|足够大|Is this bag big enough for your laptop?|这个包够大，能装下你的电脑吗？|big difference|很大差别|A good pillow makes a big difference.|一个好枕头会带来很大差别。
    small|I'd like a small coffee, please.|请给我一小杯咖啡。|small change|零钱|Do you have any small change?|你有零钱吗？|small size|小号|Do you have this shirt in a small size?|这件衬衫有小号吗？
    fast|The internet is much faster today.|今天网速快多了。|fast food|快餐|We had fast food on the way home.|我们回家路上吃了快餐。|too fast|太快|You're speaking a little too fast.|你说得有点太快了。
    slow|The service is a little slow today.|今天服务有点慢。|slow down|慢下来|Please slow down near the school.|学校附近请减速。|slow traffic|缓慢的车流|We got stuck in slow traffic.|我们堵在缓慢的车流里。
    early|I woke up early to catch the first train.|我早起赶第一班火车。|early morning|清晨|The streets are quiet in the early morning.|清晨街道很安静。|arrive early|提前到达|Try to arrive ten minutes early.|尽量提前十分钟到。
    late|Sorry I'm late. The bus didn't come.|抱歉我迟到了，公交车没来。|stay up late|熬夜|I stayed up late watching a movie.|我熬夜看了一部电影。|running late|快迟到了|I'm running late, so start without me.|我快迟到了，你们不用等我。
    free|Are you free for lunch tomorrow?|你明天有空一起吃午饭吗？|feel free|随意|Feel free to use the kitchen.|厨房你可以随意使用。|free of charge|免费|Children under five travel free of charge.|五岁以下儿童免费乘车。
    """

    private static func makeGrammarEntries() -> [GrammarEntry] {
        grammarData
            .split(separator: "\n")
            .enumerated()
            .compactMap { index, line in
                let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
                guard fields.count == 5 else { return nil }
                return GrammarEntry(
                    id: "g-\(String(format: "%03d", index + 1))",
                    title: fields[0],
                    explanation: fields[1],
                    pattern: fields[2],
                    example: fields[3],
                    translation: fields[4]
                )
            }
    }

    private static let baseWordData = """
    hello|/həˈloʊ/|感叹词|你好
    thanks|/θæŋks/|名词|感谢
    sorry|/ˈsɑːri/|形容词|抱歉的
    please|/pliːz/|副词|请
    friend|/frend/|名词|朋友
    family|/ˈfæməli/|名词|家人
    name|/neɪm/|名词|名字
    time|/taɪm/|名词|时间
    day|/deɪ/|名词|一天
    morning|/ˈmɔːrnɪŋ/|名词|早晨
    evening|/ˈiːvnɪŋ/|名词|傍晚
    home|/hoʊm/|名词|家
    room|/ruːm/|名词|房间
    food|/fuːd/|名词|食物
    water|/ˈwɔːtər/|名词|水
    coffee|/ˈkɔːfi/|名词|咖啡
    breakfast|/ˈbrekfəst/|名词|早餐
    lunch|/lʌntʃ/|名词|午餐
    dinner|/ˈdɪnər/|名词|晚餐
    restaurant|/ˈrestərɑːnt/|名词|餐厅
    shop|/ʃɑːp/|名词|商店
    money|/ˈmʌni/|名词|钱
    price|/praɪs/|名词|价格
    ticket|/ˈtɪkɪt/|名词|票
    bus|/bʌs/|名词|公交车
    train|/treɪn/|名词|火车
    airport|/ˈerpɔːrt/|名词|机场
    hotel|/hoʊˈtel/|名词|酒店
    street|/striːt/|名词|街道
    place|/pleɪs/|名词|地方
    work|/wɜːrk/|名词|工作
    office|/ˈɔːfɪs/|名词|办公室
    meeting|/ˈmiːtɪŋ/|名词|会议
    question|/ˈkwestʃən/|名词|问题
    answer|/ˈænsər/|名词|答案
    idea|/aɪˈdiːə/|名词|想法
    problem|/ˈprɑːbləm/|名词|问题
    help|/help/|名词|帮助
    phone|/foʊn/|名词|电话
    message|/ˈmesɪdʒ/|名词|消息
    weather|/ˈweðər/|名词|天气
    weekend|/ˌwiːkˈend/|名词|周末
    holiday|/ˈhɑːlədeɪ/|名词|假期
    language|/ˈlæŋɡwɪdʒ/|名词|语言
    English|/ˈɪŋɡlɪʃ/|名词|英语
    music|/ˈmjuːzɪk/|名词|音乐
    movie|/ˈmuːvi/|名词|电影
    book|/bʊk/|名词|书
    story|/ˈstɔːri/|名词|故事
    plan|/plæn/|名词|计划
    go|/ɡoʊ/|动词|去
    come|/kʌm/|动词|来
    eat|/iːt/|动词|吃
    drink|/drɪŋk/|动词|喝
    buy|/baɪ/|动词|购买
    pay|/peɪ/|动词|支付
    find|/faɪnd/|动词|找到
    ask|/æsk/|动词|询问
    tell|/tel/|动词|告诉
    speak|/spiːk/|动词|说
    listen|/ˈlɪsən/|动词|听
    read|/riːd/|动词|阅读
    write|/raɪt/|动词|写
    learn|/lɜːrn/|动词|学习
    remember|/rɪˈmembər/|动词|记住
    understand|/ˌʌndərˈstænd/|动词|理解
    know|/noʊ/|动词|知道
    think|/θɪŋk/|动词|思考
    want|/wɑːnt/|动词|想要
    need|/niːd/|动词|需要
    like|/laɪk/|动词|喜欢
    love|/lʌv/|动词|喜爱
    call|/kɔːl/|动词|打电话
    wait|/weɪt/|动词|等待
    start|/stɑːrt/|动词|开始
    finish|/ˈfɪnɪʃ/|动词|完成
    try|/traɪ/|动词|尝试
    use|/juːz/|动词|使用
    make|/meɪk/|动词|制作
    take|/teɪk/|动词|拿取
    give|/ɡɪv/|动词|给予
    happy|/ˈhæpi/|形容词|开心的
    busy|/ˈbɪzi/|形容词|忙碌的
    tired|/ˈtaɪərd/|形容词|疲惫的
    ready|/ˈredi/|形容词|准备好的
    easy|/ˈiːzi/|形容词|容易的
    difficult|/ˈdɪfɪkəlt/|形容词|困难的
    important|/ɪmˈpɔːrtənt/|形容词|重要的
    interesting|/ˈɪntrəstɪŋ/|形容词|有趣的
    good|/ɡʊd/|形容词|好的
    bad|/bæd/|形容词|不好的
    new|/nuː/|形容词|新的
    old|/oʊld/|形容词|旧的
    big|/bɪɡ/|形容词|大的
    small|/smɔːl/|形容词|小的
    fast|/fæst/|形容词|快的
    slow|/sloʊ/|形容词|慢的
    early|/ˈɜːrli/|形容词|早的
    late|/leɪt/|形容词|晚的
    free|/friː/|形容词|有空的
    """

    private static let grammarData = """
    一般现在时|表示习惯、事实和经常发生的动作。|主语 + 动词原形/第三人称单数|I make coffee every morning.|我每天早上煮咖啡。
    一般过去时|表示过去某个时间已经发生并结束的动作。|主语 + 动词过去式|We cooked dinner at home yesterday.|我们昨天在家做了晚饭。
    一般将来时 will|表示临时决定、预测或将来的动作。|主语 + will + 动词原形|I will pick you up at the station.|我会去车站接你。
    be going to|表示已有计划或有迹象将要发生的事。|主语 + be going to + 动词原形|We are going to cook dinner.|我们打算做晚饭。
    现在进行时|表示此刻正在进行的动作。|主语 + be + 动词-ing|She is reading a book now.|她现在正在读书。
    现在完成时|表示过去发生但与现在有关的经历或结果。|主语 + have/has + 过去分词|I have lost my house keys.|我把家门钥匙弄丢了。
    be 动词肯定句|用 am、is、are 描述身份、状态或位置。|主语 + am/is/are + 表语|They are at home.|他们在家。
    be 动词否定句|在 be 动词后加 not 表示否定。|主语 + am/is/are + not|I am not busy today.|我今天不忙。
    be 动词一般疑问句|把 be 动词放到主语前提问。|Am/Is/Are + 主语 + 表语？|Are you ready?|你准备好了吗？
    实义动词否定句|一般现在时用 do not 或 does not 构成否定。|主语 + do/does not + 动词原形|He does not drink coffee.|他不喝咖啡。
    实义动词一般疑问句|一般现在时用 do 或 does 放在句首提问。|Do/Does + 主语 + 动词原形？|Do you take the bus home?|你坐公交车回家吗？
    特殊疑问词 what|询问事物、动作或信息。|What + 一般疑问句？|What do you need?|你需要什么？
    特殊疑问词 where|询问地点或方向。|Where + 一般疑问句？|Where is the nearest pharmacy?|最近的药店在哪里？
    特殊疑问词 when|询问时间。|When + 一般疑问句？|When does the store close?|商店什么时候关门？
    特殊疑问词 why|询问原因，回答常使用 because。|Why + 一般疑问句？|Why are you late?|你为什么迟到了？
    特殊疑问词 who|询问人物或身份。|Who + 动词/一般疑问句？|Who is that person?|那个人是谁？
    特殊疑问词 how|询问方式、状态或程度。|How + 一般疑问句？|How do we get to the train station?|我们怎么去火车站？
    How much|询问价格或不可数名词的数量。|How much + 不可数名词/一般疑问句？|How much is this bottle of water?|这瓶水多少钱？
    How many|询问可数名词的数量。|How many + 复数名词 + 一般疑问句？|How many eggs do we need?|我们需要多少个鸡蛋？
    How often|询问动作发生的频率。|How often + 一般疑问句？|How often do you exercise?|你多久锻炼一次？
    can 表示能力|用 can 表示会做或有能力做某事。|主语 + can + 动词原形|I can cook a few simple dishes.|我会做几道简单的菜。
    can 表示请求|用 Can you...? 提出日常请求。|Can you + 动词原形？|Can you help me?|你能帮我吗？
    could 礼貌请求|could 比 can 更委婉。|Could you + 动词原形？|Could you say that again?|你能再说一遍吗？
    may 表示许可|用 may 较正式地询问或给予许可。|May I + 动词原形？|May I come in?|我可以进来吗？
    should 表示建议|用 should 给出建议或表达应该做的事。|主语 + should + 动词原形|You should get some rest.|你应该休息一下。
    must 表示必须|表示强烈义务或确定判断。|主语 + must + 动词原形|You must wear a seat belt.|你必须系安全带。
    have to|表示因规则或现实情况而不得不做。|主语 + have/has to + 动词原形|I have to buy groceries after work.|我下班后得去买菜。
    would like|比 want 更礼貌地表达想要。|主语 + would like + 名词/to do|I would like some water.|我想要一些水。
    there is|表示某处有一个事物或不可数事物。|There is + 单数/不可数名词|There is a shop nearby.|附近有一家商店。
    there are|表示某处有多个事物。|There are + 复数名词|There are two seats here.|这里有两个座位。
    可数名词单数|单数可数名词通常需要冠词或限定词。|a/an/the + 单数名词|I need a pen.|我需要一支笔。
    可数名词复数|表示多个事物时通常给名词加复数形式。|数量词 + 复数名词|We bought three apples.|我们买了三个苹果。
    不可数名词|不可数名词通常不直接与 a 或 an 连用。|some/much + 不可数名词|Can I have some water?|我可以喝点水吗？
    不定冠词 a/an|首次提到一个非特定的单数事物时使用。|a + 辅音音素；an + 元音音素|She has an idea.|她有一个想法。
    定冠词 the|谈论双方都知道或特定的事物时使用。|the + 名词|The bus is late.|这辆公交车晚点了。
    some|多用于肯定句，表示一些或某些。|some + 复数/不可数名词|I need some help.|我需要一些帮助。
    any|常用于否定句和疑问句。|any + 复数/不可数名词|Do you have any questions?|你有任何问题吗？
    this 和 that|this 指较近的单数事物，that 指较远的单数事物。|this/that + 单数名词|This bag is mine, and that one is yours.|这个包是我的，那个是你的。
    these 和 those|these 指较近的复数事物，those 指较远的复数事物。|these/those + 复数名词|These tomatoes are cheaper than those.|这些西红柿比那些便宜。
    形容词位置|形容词可放在名词前或系动词后。|形容词 + 名词；be + 形容词|The room is small.|这个房间很小。
    副词修饰动词|副词说明动作发生的方式、频率或程度。|动词 + 副词|Please speak slowly.|请说慢一点。
    频率副词|always、usually 等通常放在实义动词前、be 动词后。|主语 + 频率副词 + 动词|I usually cook at home on weekdays.|工作日我通常在家做饭。
    比较级|比较两个事物时使用形容词比较级。|A + be + 比较级 + than + B|This train is faster than the bus.|这列火车比公交车快。
    最高级|比较三个或更多事物时使用最高级。|the + 形容词最高级|This is the best choice.|这是最好的选择。
    as...as|表示两者在某方面程度相同。|A + be + as + 形容词 + as + B|This room is as big as that one.|这个房间和那个一样大。
    too|表示程度过高，常带有不合适的含义。|too + 形容词|The coffee is too hot.|咖啡太烫了。
    enough|表示程度或数量足够。|形容词 + enough；enough + 名词|The room is big enough.|这个房间足够大。
    because|连接原因，回答 why 提出的问题。|结果 + because + 原因|I stayed home because it rained.|因为下雨，我待在家里。
    so|连接原因和结果，强调结果。|原因 + so + 结果|I was tired, so I went home.|我累了，所以回家了。
    and|连接并列的词、短语或句子。|A + and + B|We bought bread and milk.|我们买了面包和牛奶。
    but|连接意义相反或转折的内容。|A + but + B|The room is small but comfortable.|房间虽小但很舒适。
    or|表示选择或另一种可能。|A + or + B|Would you like tea or coffee?|你想要茶还是咖啡？
    to do 不定式|常在 want、need、plan 等动词后表示目的或计划。|动词 + to + 动词原形|I need to charge my phone.|我需要给手机充电。
    动名词作宾语|enjoy、finish 等动词后常接动词-ing。|动词 + 动词-ing|I enjoy walking after dinner.|我喜欢晚饭后散步。
    介词 in|用于较大的地点、月份、年份或一天中的时段。|in + 地点/时间|I exercise in the morning.|我早上锻炼。
    介词 on|用于具体日期、星期或物体表面。|on + 日期/星期|The market is open on Saturday.|集市星期六开放。
    介词 at|用于具体时刻或较小、明确的地点。|at + 时间/地点|Let's meet at nine.|我们九点见。
    介词 for|表示持续时间、用途或对象。|for + 时间段/名词|I waited for ten minutes.|我等了十分钟。
    介词 with|表示和某人一起或使用某种工具。|with + 人/工具|I went with my friend.|我和朋友一起去了。
    祈使句|用动词原形开头表达指令、建议或请求。|动词原形 + 其他|Please wait here.|请在这里等。
    """
}
