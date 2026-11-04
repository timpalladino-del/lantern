import Foundation

/// Every word list the games draw from. Family-friendly, no brands, no screens needed.
enum GamesLibrary {

    // MARK: Heads up, act it out, hangman, twenty questions

    struct WordCategory: Identifiable, Hashable {
        let id: String
        let title: String
        let symbol: String
        let words: [String]
        let actable: Bool   // good for charades
    }

    static let categories: [WordCategory] = [
        WordCategory(id: "animals", title: "Animals", symbol: "pawprint.fill", words: [
            "Elephant", "Giraffe", "Penguin", "Kangaroo", "Octopus", "Flamingo", "Crocodile", "Hamster", "Dolphin", "Owl",
            "Gorilla", "Sloth", "Chicken", "Snake", "Butterfly", "Shark", "Hippo", "Squirrel", "Frog", "Peacock",
            "Bat", "Camel", "Lobster", "Raccoon", "Turtle", "Seal", "Eagle", "Mosquito", "Goat", "Jellyfish",
            "Koala", "Cheetah", "Spider", "Walrus", "Parrot", "Skunk", "Beaver", "Ostrich", "Zebra", "Moose",
        ], actable: true),
        WordCategory(id: "jobs", title: "Jobs", symbol: "briefcase.fill", words: [
            "Firefighter", "Dentist", "Chef", "Pilot", "Lifeguard", "Mail carrier", "Farmer", "Plumber", "Teacher", "Astronaut",
            "Barber", "Nurse", "Photographer", "Mechanic", "Librarian", "Magician", "Lumberjack", "Surgeon", "Referee", "Drummer",
            "Waiter", "Detective", "Zookeeper", "Painter", "Bus driver", "Ballet dancer", "Weather forecaster", "Scuba diver", "Clown", "Electrician",
            "Judge", "Fisherman", "Veterinarian", "Carpenter", "Tour guide", "Beekeeper", "Opera singer", "Window washer", "Tailor", "Cowboy",
        ], actable: true),
        WordCategory(id: "food", title: "Food", symbol: "fork.knife", words: [
            "Spaghetti", "Popcorn", "Watermelon", "Pancakes", "Taco", "Pineapple", "Ice cream cone", "Corn on the cob", "Peanut butter", "Pizza",
            "Banana", "Hot soup", "Lollipop", "Hamburger", "Sushi", "Grapes", "Bubble gum", "Cereal", "Doughnut", "Lemon",
            "Marshmallow", "Pretzel", "Coconut", "Chili", "Toast", "Oatmeal", "Jelly beans", "Mashed potatoes", "Eggs", "Pickle",
            "Burrito", "Cheese", "Cupcake", "Apple pie", "Hot dog", "Strawberry", "Noodles", "Carrot", "Honey", "Yogurt",
        ], actable: true),
        WordCategory(id: "home", title: "Around the house", symbol: "house.fill", words: [
            "Toothbrush", "Vacuum cleaner", "Umbrella", "Washing machine", "Flashlight", "Rocking chair", "Lawn mower", "Blender", "Ladder", "Alarm clock",
            "Garden hose", "Hair dryer", "Microwave", "Pillow", "Remote control", "Stapler", "Bathtub", "Doorbell", "Ceiling fan", "Broom",
            "Ironing board", "Trash can", "Candle", "Wheelbarrow", "Toaster", "Mirror", "Kitchen sink", "Bunk bed", "Thermostat", "Screwdriver",
            "Can opener", "Mop", "Fire extinguisher", "Bookshelf", "Shower curtain", "Fridge", "Coffee pot", "Mailbox", "Light switch", "Cooler",
        ], actable: true),
        WordCategory(id: "sports", title: "Sports and hobbies", symbol: "figure.run", words: [
            "Basketball", "Swimming", "Bowling", "Skateboarding", "Fishing", "Golf", "Karate", "Juggling", "Yoga", "Surfing",
            "Baseball", "Tennis", "Knitting", "Archery", "Gymnastics", "Hockey", "Jump rope", "Rock climbing", "Chess", "Soccer",
            "Ping pong", "Boxing", "Horseback riding", "Weightlifting", "Volleyball", "Cheerleading", "Football", "Skiing", "Painting", "Frisbee",
            "Cycling", "Hula hoop", "Canoeing", "Hopscotch", "Dancing", "Gardening", "Wrestling", "Badminton", "Running", "Ice skating",
        ], actable: true),
        WordCategory(id: "places", title: "Places", symbol: "map.fill", words: [
            "Beach", "Library", "Dentist's office", "Airport", "Zoo", "Grocery store", "Haunted house", "Space station", "Gas station", "Jungle",
            "Movie theater", "Playground", "Hospital", "Circus", "Farm", "Desert", "Submarine", "Bakery", "Ski lodge", "Volcano",
            "Classroom", "Campsite", "Castle", "Swimming pool", "Post office", "Laundromat", "Pirate ship", "Amusement park", "Igloo", "Pet store",
            "Waterfall", "Car wash", "Parking garage", "Treehouse", "Barbershop", "Train station", "Elevator", "Cave", "Lighthouse", "Attic",
        ], actable: true),
        WordCategory(id: "actions", title: "Things people do", symbol: "hands.clap.fill", words: [
            "Brushing teeth", "Changing a tire", "Walking a dog", "Making a sandwich", "Sneezing", "Flying a kite", "Milking a cow", "Blowing out candles", "Shoveling snow", "Taking a selfie",
            "Building a snowman", "Washing dishes", "Riding a roller coaster", "Playing the drums", "Putting on makeup", "Catching a fish", "Opening a stuck jar", "Wrapping a gift", "Rowing a boat", "Eating spaghetti",
            "Texting", "Sleepwalking", "Doing laundry", "Baking cookies", "Walking on a tightrope", "Slipping on ice", "Hiding from a bee", "Tying shoes", "Petting a cat", "Mowing the lawn",
            "Waking up late", "Driving in traffic", "Carrying groceries", "Blowing up a balloon", "Getting a haircut", "Eating something sour", "Playing hide and seek", "Trying on shoes", "Watering plants", "Dancing at a wedding",
        ], actable: true),
    ]

    static func category(_ id: String) -> WordCategory { categories.first { $0.id == id } ?? categories[0] }

    /// Everything that works as a hangman word (one or two words, letters and spaces only).
    static var hangmanWords: [(word: String, hint: String)] {
        categories.flatMap { c in c.words.filter { $0.allSatisfy { $0.isLetter || $0 == " " } }.map { ($0, c.title) } }
    }

    // MARK: Would you rather

    static let wouldYouRather: [(String, String)] = [
        ("Be able to fly", "Be able to breathe underwater"),
        ("Have a pet dragon", "Have a pet dinosaur"),
        ("Eat only pizza for a year", "Eat only ice cream for a year"),
        ("Be invisible", "Be able to read minds"),
        ("Live in a treehouse", "Live on a boat"),
        ("Have hands for feet", "Have feet for hands"),
        ("Always have to sing instead of talk", "Always have to dance instead of walk"),
        ("Be ten feet tall", "Be ten inches tall"),
        ("Never eat candy again", "Never watch a movie again"),
        ("Have a snowball fight", "Have a water balloon fight"),
        ("Be the fastest runner in the world", "Be the strongest person in the world"),
        ("Have a robot that does your chores", "Have a robot that does your homework"),
        ("Visit the moon", "Visit the bottom of the ocean"),
        ("Talk to animals", "Speak every human language"),
        ("Have a swimming pool in your house", "Have a movie theater in your house"),
        ("Only whisper for a week", "Only shout for a week"),
        ("Eat a bug", "Kiss a frog"),
        ("Have no homework ever", "Have no bedtime ever"),
        ("Be a famous musician", "Be a famous athlete"),
        ("Be really good at drawing", "Be really good at telling jokes"),
        ("Ride a camel", "Ride an elephant"),
        ("Have a tail", "Have wings"),
        ("Sleep in a tent", "Sleep in a hammock"),
        ("Find a treasure map", "Find a magic lamp"),
        ("Have your own island", "Have your own castle"),
        ("Be a wizard", "Be a superhero"),
        ("Live in the summer forever", "Live in the winter forever"),
        ("Eat a whole lemon", "Eat a whole onion"),
        ("Be able to pause time", "Be able to rewind time"),
        ("Have a nose that glows", "Have ears that wiggle"),
        ("Drive a fire truck", "Drive a race car"),
        ("Never have to brush your teeth", "Never have to take a bath"),
        ("Have a pet monkey", "Have a pet penguin"),
        ("Be the only person who can see in the dark", "Be the only person who never gets cold"),
        ("Make your own cartoon", "Star in your own cartoon"),
        ("Have hair that changes color with your mood", "Have eyes that change color with your mood"),
        ("Live without music", "Live without games"),
        ("Be a giant", "Be a tiny person"),
        ("Have a rainbow follow you everywhere", "Have a cloud follow you everywhere"),
        ("Eat breakfast for every meal", "Eat dinner for every meal"),
        ("Be a famous chef", "Be a famous inventor"),
        ("Swim with dolphins", "Fly with eagles"),
        ("Have a slide instead of stairs", "Have a trampoline instead of a bed"),
        ("Only be able to walk backwards", "Only be able to walk sideways"),
        ("Have a jet pack", "Have a hoverboard that really hovers"),
        ("Taste everything as chocolate", "Smell everything as fresh bread"),
        ("Be able to jump as high as a house", "Be able to run as fast as a car"),
        ("Go camping in the mountains", "Go camping at the beach"),
        ("Have a secret tunnel under your house", "Have a secret room behind a bookshelf"),
        ("Be a dog for a day", "Be a cat for a day"),
        ("Have super hearing", "Have super sight"),
        ("Meet your favorite book character", "Meet your great-great-grandparents"),
        ("Have a birthday every month", "Have summer vacation twice a year"),
        ("Be able to talk to plants", "Be able to talk to the weather"),
        ("Give up your pillow", "Give up your blanket"),
        ("Own a bakery", "Own a toy store"),
        ("Live in a world with no cars", "Live in a world with no phones"),
        ("Be stuck in an elevator with a clown", "Be stuck in an elevator with a mime"),
        ("Always smell like popcorn", "Always smell like pine trees"),
        ("Have a magic backpack", "Have magic shoes"),
    ]

    // MARK: Twenty questions

    static let secretThings: [(thing: String, kind: String)] =
        category("animals").words.map { ($0, "an animal") } +
        category("food").words.map { ($0, "something you eat") } +
        category("home").words.map { ($0, "something in a house") } +
        category("places").words.map { ($0, "a place") }

    // MARK: Story chain

    static let storyStarters: [String] = [
        "The lights went out, and that is when the cat started talking.",
        "Nobody believed Sam about the dragon in the garage until Tuesday.",
        "There was a door in the basement that had never been there before.",
        "Grandma's old radio only played songs from the year 2099.",
        "The pizza arrived, but nobody had ordered it, and the box was warm from the inside.",
        "On the first day of summer, every dog in town learned to ride a bike.",
        "The flashlight beam landed on a tiny door in the baseboard.",
        "Max found a map in his cereal box, and it had an X right on his house.",
        "The storm blew in a bottle, and in the bottle was a tiny ship, and on the ship was a crew.",
        "Every night at nine, the fridge hummed a song, and tonight it hummed a new one.",
        "The babysitter turned out to be a retired pirate.",
        "A single snowflake fell in July, and it did not melt.",
        "The school bus took a wrong turn and ended up at the beach.",
        "Lily woke up to find her shadow had gone on vacation without her.",
        "The old lighthouse blinked a message, and only the dog could read it.",
        "In the attic, a trunk full of hats, and each hat was a different job.",
        "The power came back on, but the TV showed the house from the outside.",
        "There was a knock at the door, and when they opened it, a goat handed them a letter.",
        "The campfire crackled, and the sparks spelled out a name.",
        "Our neighbor built a rocket out of lawn chairs, and it actually worked.",
        "The whistle in the toolkit summoned something that was not a rescue team.",
        "Every time Dad sneezed, the furniture moved one inch to the left.",
        "The twins found a second house inside their house.",
        "The library book was due in 1952.",
        "The hurricane left behind a boat in the backyard, and the boat had a name: Yours.",
        "Grandpa's compass always pointed at dessert.",
        "A robot knocked on the window and asked for directions to the moon.",
        "The candle flickered, and the shadow on the wall waved back.",
        "Hidden inside the old piano was a staircase going down.",
        "On the night of the big storm, the mailbox started receiving letters from the future.",
    ]

    static let storyTwists: [String] = [
        "Suddenly, it started to rain fish.",
        "Then a tiny voice said, \"Excuse me, that's mine.\"",
        "The floor turned out to be the ceiling.",
        "A dog in a top hat wandered in.",
        "Everyone realized they were holding the map upside down.",
        "The lights flickered, and the room was now a forest.",
        "Someone's stomach growled so loudly that the windows shook.",
        "A message appeared written in frosting.",
        "The youngest person in the story knew exactly what to do.",
        "The ground began to tilt like a boat.",
        "A friendly bear offered to help, for a price.",
        "They found a key with no lock anywhere.",
        "Something very small roared.",
        "It was all a dream, until it wasn't.",
        "The villain apologized and asked for a sandwich.",
        "Time stopped, except for the cat.",
        "The hero sneezed and everything changed color.",
        "The bus driver was the hero's grandmother all along.",
        "The treasure was a box of socks, but very special socks.",
        "A song started playing that only one person could hear.",
        "The door opened onto the roof of a train.",
        "They all had to whisper, or the balloon would pop.",
        "The whole thing was being watched by a very bored owl.",
        "Someone found a sandwich that granted one wish.",
        "The chase ended at a bake sale.",
        "The lantern lit up, and it showed the way home.",
        "A gust of wind carried away the one thing they needed.",
        "The mirror showed a different room.",
        "Right then, the power came back on.",
        "The ending was happy, but only for the pigeons.",
    ]

    // MARK: Flashlight scavenger hunt

    static let huntPrompts: [String] = [
        "Something red", "Something softer than a pillow", "Something that makes noise", "Something older than you", "Something with a battery",
        "Something round", "Something you wear on your feet", "Something that smells good", "Something that rhymes with cat", "Something that opens and closes",
        "Something with writing on it", "Something that floats", "Something cold", "Something with stripes", "Something blue",
        "Something you can draw with", "Something that comes in a pair", "Something with a handle", "Something that spins", "Something sticky",
        "Something you'd pack for a trip", "Something heavier than a shoe", "Something shiny", "Something with a face on it", "Something that bounces",
        "Something from the kitchen", "Something that folds", "Something you can see through", "Something with a lid", "Something with four legs",
        "Something that starts with the letter B", "Something you'd find in a go-bag", "Something fuzzy", "Something square", "Something that's a tool",
        "Something tiny enough to fit in a pocket", "Something green", "Something that glows", "Something with buttons", "Something you can stack",
    ]

    // MARK: Shadow puppets

    struct Puppet: Identifiable { let id: String; let name: String; let symbol: String; let steps: [String] }
    static let puppets: [Puppet] = [
        Puppet(id: "dog", name: "Dog", symbol: "dog.fill", steps: [
            "Hold one hand sideways, palm facing the wall, thumb up.",
            "Bend your pinky down to make the lower jaw.",
            "Keep the thumb straight up for the ear.",
            "Move the pinky up and down to make it bark.",
        ]),
        Puppet(id: "rabbit", name: "Rabbit", symbol: "hare.fill", steps: [
            "Make a fist with your thumb tucked in.",
            "Point your index and middle fingers straight up for the ears.",
            "Wiggle the two fingers to twitch the ears.",
            "Bob the whole hand to make it hop.",
        ]),
        Puppet(id: "bird", name: "Flying bird", symbol: "bird.fill", steps: [
            "Hook your thumbs together, palms facing you.",
            "Spread your fingers out to each side for the wings.",
            "Flap your hands slowly from the wrists.",
            "Move toward the light to make the bird grow.",
        ]),
        Puppet(id: "swan", name: "Swan", symbol: "drop.fill", steps: [
            "Bend one arm at the elbow, forearm straight up.",
            "Curve your hand forward and let the fingers droop for the beak.",
            "Hold the other hand flat behind the elbow for the tail feathers.",
            "Sway the arm slowly to make it glide.",
        ]),
        Puppet(id: "deer", name: "Deer", symbol: "leaf.fill", steps: [
            "Hold one hand sideways with the fingers together for the head.",
            "Cross the other hand behind it with fingers spread wide for the antlers.",
            "Tip the head down to make it graze.",
        ]),
        Puppet(id: "wolf", name: "Wolf", symbol: "moon.fill", steps: [
            "Hold your hand sideways, fingers together, thumb pointing up for the ear.",
            "Bend your index finger down a little for the forehead.",
            "Drop the pinky and ring finger to open the jaw.",
            "Tilt the head back and open the jaw to howl.",
        ]),
        Puppet(id: "crab", name: "Crab", symbol: "circle.grid.cross.fill", steps: [
            "Cross your wrists with palms facing down.",
            "Curl your fingers into claws.",
            "Open and close the thumbs against the fingers to snap.",
            "Scuttle the hands sideways.",
        ]),
        Puppet(id: "elephant", name: "Elephant", symbol: "tortoise.fill", steps: [
            "Hold one arm out with the hand drooping down for the trunk.",
            "Spread the other hand flat behind the wrist for the ear.",
            "Curl the trunk up slowly, then let it drop.",
        ]),
        Puppet(id: "snail", name: "Snail", symbol: "circle.circle.fill", steps: [
            "Make a fist with one hand for the shell.",
            "Lay the other hand flat underneath, with two fingers pointing forward for the feelers.",
            "Slide the flat hand very slowly along.",
        ]),
    ]

    // MARK: Trivia

    struct Question: Identifiable, Hashable {
        let id: String
        let prompt: String
        let options: [String]
        let answer: Int
        let note: String        // one line shown after answering
        let readiness: Bool     // true when it teaches something from the know-how cards
    }

    static let questions: [Question] = [
        // Readiness, from the sources the know-how cards cite.
        Question(id: "r1", prompt: "The power goes out. How long does an unopened fridge keep food cold enough to be safe?", options: ["About 1 hour", "About 4 hours", "About 12 hours", "About 2 days"], answer: 1, note: "USDA: about 4 hours if the door stays shut. Lantern's outage mode counts it down.", readiness: true),
        Question(id: "r2", prompt: "A full freezer stays frozen without power for about how long?", options: ["4 hours", "12 hours", "24 hours", "48 hours"], answer: 3, note: "USDA: 48 hours if full, 24 hours if half full. Keep the door closed.", readiness: true),
        Question(id: "r3", prompt: "How much water should you store per person, per day?", options: ["One cup", "One quart", "One gallon", "Five gallons"], answer: 2, note: "CDC and Ready.gov: one gallon per person per day, for drinking and a little washing.", readiness: true),
        Question(id: "r4", prompt: "How far from the house should a running generator be?", options: ["In the garage with the door open", "On the porch", "At least 20 feet away", "Right under a window"], answer: 2, note: "CDC: at least 20 feet from any door, window or vent. Carbon monoxide is odorless.", readiness: true),
        Question(id: "r5", prompt: "To make water safe by boiling, bring it to a rolling boil for at least how long?", options: ["10 seconds", "1 minute", "15 minutes", "1 hour"], answer: 1, note: "CDC: a rolling boil for one minute (three minutes above 6,500 feet).", readiness: true),
        Question(id: "r6", prompt: "After adding plain bleach to a gallon of water, how long do you wait before drinking?", options: ["No wait", "5 minutes", "30 minutes", "24 hours"], answer: 2, note: "CDC: stir and wait 30 minutes. Use unscented household bleach, a few drops per gallon.", readiness: true),
        Question(id: "r7", prompt: "Perishable food that has been above 40°F for more than how long should be thrown out?", options: ["30 minutes", "2 hours", "8 hours", "A day"], answer: 1, note: "USDA: two hours. When in doubt, throw it out.", readiness: true),
        Question(id: "r8", prompt: "What does a tornado WARNING mean?", options: ["Conditions could produce one later", "One has been seen or shown on radar", "The season has started", "Wind over 30 mph"], answer: 1, note: "A watch means be ready. A warning means take shelter now.", readiness: true),
        Question(id: "r9", prompt: "Carbon monoxide is dangerous partly because it is", options: ["Bright green", "Loud", "Colorless and odorless", "Sticky"], answer: 2, note: "You cannot see or smell it. A CO alarm is the only warning. If it sounds, get outside.", readiness: true),
        Question(id: "r10", prompt: "The right first aid for a small burn is", options: ["Butter", "Ice", "Cool running water", "A tight bandage"], answer: 2, note: "Red Cross: cool running water for at least ten minutes, then a loose clean cover. No ice, no butter.", readiness: true),
        Question(id: "r11", prompt: "In an earthquake, the advice is", options: ["Run outside", "Stand in a doorway", "Drop, cover and hold on", "Call 911 first"], answer: 2, note: "FEMA: drop to the ground, get under something sturdy, hold on until the shaking stops.", readiness: true),
        Question(id: "r12", prompt: "The letters on a fire extinguisher, PASS, stand for", options: ["Point, Alarm, Spray, Stop", "Pull, Aim, Squeeze, Sweep", "Push, Alert, Shake, Spray", "Pull, Attack, Spray, Stand"], answer: 1, note: "Pull the pin, aim at the base of the fire, squeeze, sweep side to side.", readiness: true),
        Question(id: "r13", prompt: "The Morse code distress signal SOS is", options: ["Three long, three short, three long", "Three short, three long, three short", "Nine short", "Nine long"], answer: 1, note: "Dot dot dot, dash dash dash, dot dot dot. Lantern's strobe flashes it for you.", readiness: true),
        Question(id: "r14", prompt: "How much moving flood water can knock an adult off their feet?", options: ["6 inches", "2 feet", "4 feet", "Only a rushing river"], answer: 0, note: "NWS: six inches of moving water. Twelve inches can float a car. Turn around, don't drown.", readiness: true),
        Question(id: "r15", prompt: "Smoke alarms should be tested how often?", options: ["Once a month", "Once a year", "Every five years", "Only when they beep"], answer: 0, note: "NFPA: test monthly, replace batteries at least yearly, replace the whole alarm every ten years.", readiness: true),
        Question(id: "r16", prompt: "The Poison Control number in the United States is", options: ["911", "211", "1-800-222-1222", "311"], answer: 2, note: "Free, 24 hours, every day. It is in Lantern's contacts list.", readiness: true),
        Question(id: "r17", prompt: "Atlantic hurricane season runs from", options: ["January to March", "June 1 to November 30", "All year", "September only"], answer: 1, note: "June 1 to November 30, with the busiest stretch in August, September and October.", readiness: true),
        Question(id: "r18", prompt: "A Category 1 hurricane starts at sustained winds of", options: ["39 mph", "74 mph", "111 mph", "157 mph"], answer: 1, note: "The Saffir-Simpson scale: 74 mph for Category 1, 157 mph and up for Category 5.", readiness: true),
        Question(id: "r19", prompt: "If you can hear thunder, lightning is", options: ["Too far to matter", "Close enough to hit you", "Only over water", "Already over"], answer: 1, note: "NWS: when thunder roars, go indoors. Wait 30 minutes after the last thunder.", readiness: true),
        Question(id: "r20", prompt: "Hypothermia begins when body temperature drops below", options: ["98°F", "95°F", "90°F", "85°F"], answer: 1, note: "CDC: below 95°F. Shivering, confusion and fumbling hands are the early signs.", readiness: true),
        Question(id: "r21", prompt: "During CPR, chest compressions should be about how fast?", options: ["30 a minute", "60 a minute", "100 to 120 a minute", "200 a minute"], answer: 2, note: "Red Cross: 100 to 120 per minute, pushing at least two inches deep on an adult.", readiness: true),
        Question(id: "r22", prompt: "Which of these keeps longest in the pantry, unopened?", options: ["Fresh milk", "Bread", "Canned beans", "Bananas"], answer: 2, note: "USDA FoodKeeper: low-acid canned goods keep two to five years. Lantern's shelf-life library has the rest.", readiness: true),
        Question(id: "r23", prompt: "Ready.gov says to keep food and water for at least how many days?", options: ["One", "Three", "Fourteen", "Thirty"], answer: 1, note: "At least three days; two weeks is better where storms knock power out for a while.", readiness: true),
        Question(id: "r24", prompt: "Frostbite most often hits", options: ["The stomach", "Fingers, toes, nose and ears", "The knees", "The back"], answer: 1, note: "The parts farthest from the heart. Warm them slowly with body heat, never rub.", readiness: true),
        Question(id: "r25", prompt: "NOAA Weather Radio broadcasts on how many frequencies?", options: ["One", "Three", "Seven", "Twenty"], answer: 2, note: "Seven, between 162.400 and 162.550 MHz. They are listed in Lantern's signals card.", readiness: true),
        Question(id: "r26", prompt: "In a storm, which do you notice first?", options: ["Thunder", "Lightning", "They arrive together", "Depends on the wind"], answer: 1, note: "Light travels far faster than sound. Count the seconds between them and divide by five for the miles.", readiness: true),
        Question(id: "r27", prompt: "Which number reaches community services like shelters and food help?", options: ["211", "411", "511", "811"], answer: 0, note: "211 for community services, 911 for emergencies, 811 before you dig.", readiness: true),
        Question(id: "r28", prompt: "A person can usually go about how long without water?", options: ["A few hours", "About three days", "About three weeks", "About three months"], answer: 1, note: "The rough rule of threes: three minutes without air, three days without water, three weeks without food.", readiness: true),

        // General knowledge, easy enough for the youngest, fun for everyone.
        Question(id: "g1", prompt: "How many legs does a spider have?", options: ["Six", "Eight", "Ten", "Twelve"], answer: 1, note: "Eight. Insects have six.", readiness: false),
        Question(id: "g2", prompt: "Which planet is called the Red Planet?", options: ["Venus", "Mars", "Jupiter", "Saturn"], answer: 1, note: "Mars, from the rusty iron in its soil.", readiness: false),
        Question(id: "g3", prompt: "What is the largest ocean?", options: ["Atlantic", "Indian", "Arctic", "Pacific"], answer: 3, note: "The Pacific covers about a third of the planet.", readiness: false),
        Question(id: "g4", prompt: "What do bees make?", options: ["Butter", "Honey", "Syrup", "Jam"], answer: 1, note: "Honey, which never spoils.", readiness: false),
        Question(id: "g5", prompt: "How many days are in a leap year?", options: ["364", "365", "366", "367"], answer: 2, note: "366. February gets a 29th day.", readiness: false),
        Question(id: "g6", prompt: "What gas do plants take in to make food?", options: ["Oxygen", "Helium", "Carbon dioxide", "Nitrogen"], answer: 2, note: "Carbon dioxide in, oxygen out.", readiness: false),
        Question(id: "g7", prompt: "What is the fastest land animal?", options: ["Horse", "Cheetah", "Greyhound", "Kangaroo"], answer: 1, note: "A cheetah can top 60 miles an hour for a few seconds.", readiness: false),
        Question(id: "g8", prompt: "How many continents are there?", options: ["Five", "Six", "Seven", "Nine"], answer: 2, note: "Seven: Africa, Antarctica, Asia, Australia, Europe, North America, South America.", readiness: false),
        Question(id: "g9", prompt: "Water freezes at what temperature in Fahrenheit?", options: ["0°F", "32°F", "50°F", "100°F"], answer: 1, note: "32°F, which is 0°C.", readiness: false),
        Question(id: "g10", prompt: "What is the largest animal that has ever lived?", options: ["Elephant", "Blue whale", "Giraffe", "T. rex"], answer: 1, note: "The blue whale, longer than two school buses.", readiness: false),
        Question(id: "g11", prompt: "How many sides does a hexagon have?", options: ["Five", "Six", "Seven", "Eight"], answer: 1, note: "Six, like a honeycomb cell.", readiness: false),
        Question(id: "g12", prompt: "What is the tallest animal?", options: ["Elephant", "Ostrich", "Giraffe", "Moose"], answer: 2, note: "A giraffe can be 18 feet tall.", readiness: false),
        Question(id: "g13", prompt: "What does a caterpillar turn into?", options: ["A beetle", "A butterfly or moth", "A bee", "A dragonfly"], answer: 1, note: "It spends a while in a chrysalis or cocoon first.", readiness: false),
        Question(id: "g14", prompt: "Which of these birds cannot fly?", options: ["Owl", "Penguin", "Parrot", "Pigeon"], answer: 1, note: "Penguins swim instead, and they are very good at it.", readiness: false),
        Question(id: "g15", prompt: "What is the closest star to Earth?", options: ["The North Star", "The Sun", "Sirius", "The Moon"], answer: 1, note: "The Sun. The Moon is not a star.", readiness: false),
        Question(id: "g16", prompt: "How many colors are in a rainbow?", options: ["Three", "Five", "Seven", "Ten"], answer: 2, note: "Red, orange, yellow, green, blue, indigo, violet.", readiness: false),
        Question(id: "g17", prompt: "What is the hardest natural material?", options: ["Steel", "Diamond", "Granite", "Bone"], answer: 1, note: "Diamond, which is carbon squeezed very hard for a very long time.", readiness: false),
        Question(id: "g18", prompt: "Which organ pumps blood around your body?", options: ["Lungs", "Brain", "Heart", "Stomach"], answer: 2, note: "About 100,000 beats a day.", readiness: false),
        Question(id: "g19", prompt: "How many bones does an adult have?", options: ["106", "206", "306", "506"], answer: 1, note: "206. Babies are born with about 300 that fuse as they grow.", readiness: false),
        Question(id: "g20", prompt: "What is the capital of the United States?", options: ["New York", "Washington, D.C.", "Los Angeles", "Chicago"], answer: 1, note: "Washington, D.C., which is not in any state.", readiness: false),
        Question(id: "g21", prompt: "Which state is the biggest by area?", options: ["Texas", "California", "Alaska", "Montana"], answer: 2, note: "Alaska is more than twice the size of Texas.", readiness: false),
        Question(id: "g22", prompt: "How many stripes are on the American flag?", options: ["Ten", "Thirteen", "Fifteen", "Fifty"], answer: 1, note: "Thirteen, for the original colonies.", readiness: false),
        Question(id: "g23", prompt: "What is 7 times 8?", options: ["48", "54", "56", "64"], answer: 2, note: "56. Five, six, seven, eight.", readiness: false),
        Question(id: "g24", prompt: "Which of these is a mammal?", options: ["Shark", "Dolphin", "Trout", "Octopus"], answer: 1, note: "Dolphins breathe air and nurse their young.", readiness: false),
        Question(id: "g25", prompt: "What is a baby kangaroo called?", options: ["A cub", "A joey", "A kit", "A pup"], answer: 1, note: "A joey, which lives in its mother's pouch at first.", readiness: false),
        Question(id: "g26", prompt: "Where do polar bears live?", options: ["Antarctica", "The Arctic", "The Alps", "The Amazon"], answer: 1, note: "The Arctic, up north. Penguins are down south, so they never meet.", readiness: false),
        Question(id: "g27", prompt: "A group of lions is called a", options: ["Herd", "Pack", "Pride", "Flock"], answer: 2, note: "A pride. Wolves come in packs.", readiness: false),
        Question(id: "g28", prompt: "What is the biggest planet in our solar system?", options: ["Earth", "Saturn", "Neptune", "Jupiter"], answer: 3, note: "Jupiter could hold more than a thousand Earths.", readiness: false),
        Question(id: "g29", prompt: "How many minutes are in a day?", options: ["600", "1,000", "1,440", "2,400"], answer: 2, note: "24 hours times 60 minutes.", readiness: false),
        Question(id: "g30", prompt: "A shape with three sides is a", options: ["Square", "Triangle", "Circle", "Pentagon"], answer: 1, note: "Tri means three.", readiness: false),
        Question(id: "g31", prompt: "How many hours are in a week?", options: ["100", "144", "168", "240"], answer: 2, note: "7 days times 24 hours.", readiness: false),
        Question(id: "g32", prompt: "Which instrument has 88 keys?", options: ["Guitar", "Piano", "Flute", "Drum"], answer: 1, note: "52 white and 36 black.", readiness: false),
        Question(id: "g33", prompt: "What is the largest living reptile?", options: ["Komodo dragon", "Saltwater crocodile", "Anaconda", "Giant tortoise"], answer: 1, note: "Saltwater crocodiles can be over 20 feet long.", readiness: false),
        Question(id: "g34", prompt: "How many teeth does a grown-up usually have?", options: ["20", "24", "32", "40"], answer: 2, note: "32, including the four wisdom teeth.", readiness: false),
        Question(id: "g35", prompt: "What do you call water that falls as ice pellets in a storm?", options: ["Sleet", "Hail", "Snow", "Frost"], answer: 1, note: "Hail forms in thunderstorms. Sleet is tiny and happens in winter.", readiness: false),
        Question(id: "g36", prompt: "Which direction does the sun rise?", options: ["North", "South", "East", "West"], answer: 2, note: "East. Lantern's compass can show you which way that is.", readiness: false),
        Question(id: "g37", prompt: "How many strings does a standard guitar have?", options: ["Four", "Five", "Six", "Eight"], answer: 2, note: "Six. A bass usually has four.", readiness: false),
        Question(id: "g38", prompt: "What is the chemical formula for water?", options: ["CO2", "H2O", "O2", "NaCl"], answer: 1, note: "Two hydrogen atoms, one oxygen.", readiness: false),
        Question(id: "g39", prompt: "Which animal sleeps standing up?", options: ["Dog", "Horse", "Cat", "Bear"], answer: 1, note: "Horses can lock their legs and doze upright.", readiness: false),
        Question(id: "g40", prompt: "What is the smallest planet in our solar system?", options: ["Mars", "Mercury", "Venus", "Pluto"], answer: 1, note: "Mercury, and it is the closest to the Sun.", readiness: false),
        Question(id: "g41", prompt: "How many zeros are in one million?", options: ["Four", "Five", "Six", "Nine"], answer: 2, note: "1,000,000. A billion has nine.", readiness: false),
        Question(id: "g42", prompt: "What do you call an animal that eats only plants?", options: ["Carnivore", "Herbivore", "Omnivore", "Insectivore"], answer: 1, note: "Herbivore. Omnivores, like people, eat both.", readiness: false),
    ]

    static func quizRound(count: Int = 10) -> [Question] {
        let r = questions.filter(\.readiness).shuffled()
        let g = questions.filter { !$0.readiness }.shuffled()
        return Array((r.prefix(count / 2) + g.prefix(count - count / 2)).shuffled())
    }
}
