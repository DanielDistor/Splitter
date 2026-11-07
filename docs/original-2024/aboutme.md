**Splitter:** Effortless Bill Management

**Project Team:** Daniel Distor

**User Audience and Needs:** Splitter is designed for anyone who enjoys dining out with friends, family, or colleagues and seeks a hassle-free way to split bills. Whether it's a casual outing, a birthday dinner, or a business lunch, our app ensures that each participant pays only for what they ordered, including proportional shares of tax and tips.


**Features and Functionality**

Splitter streamlines the process of bill management through its intuitive interface:

Welcome Screen: Easy access with options to register or sign in.

Event Management: Users can create events, adding participants and detailing the shared expenses.

Meal Exploration: For those cooking at home, the meal tab allows users to search for recipes or receive random dish suggestions.

**App In Action**

1. **Starting the App**: Upon launching Splitter, users are greeted with the welcome screen. New users can register by clicking the "Register" button.

<img width="1470" alt="starting" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/342ae665-290a-4c80-9069-4b393fd2e136">



2. **Registration Process**: After clicking "Register", users are prompted to "Sign in with email". Selecting this option advances the process.

<img width="1470" alt="registration" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/0ecb9234-7d34-46d2-8a18-648209d235d4">


3. **Email Entry**: Users should enter their email address and click "Next" to continue.

<img width="1470" alt="email" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/03169d15-c52d-4a8f-a30d-92521555293d">

4. **Account Creation**: Input name and desired password, then click "Save" to finalize the registration.

<img width="1470" alt="account" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/93b93fd6-4fac-4a1b-b4d3-9976c80862e6">

5. **Sign In**: After saving, the app redirects back to the welcome screen. Here, users can click "Sign In" and log in using their registered account.

<img width="1470" alt="signin" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/3fb5ddf0-c441-43f9-9eda-781c435d7a80">

6. **Authentication**: Enter account details and click "Sign In" to access the app.

<img width="1470" alt="auth" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/3ca5641b-b48f-4142-9b7d-5a5dfe3c898a">

7. **Navigating to Split Tab**: Authenticated users are taken to the Split tab where existing events are listed. To add a new event, click "New" located at the top right of the screen.

<img width="1470" alt="nav" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/db9447af-bbc4-4bab-ac2e-34529c2967b4">

8. **Creating an Event**: Fill in the fields for participants and dishes. Click “Add Participant” and/or “Add Dish” if needed.

<img width="1470" alt="create" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/8325b970-afae-4030-96db-e0a73d92fa50">

9. **Managing Expenses**: Scroll to the expenses section, enter all relevant financial details such as subtotal, tax, tip, and total. Click "Save Event".

<img width="1470" alt="manage" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/27924dab-42d3-4bd6-8d88-7e3f408eed73">


10. **View Updated Events**: Post-event creation, users are redirected back to the Split tab which now includes the newly added event.

<img width="1470" alt="view" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/ca744bd0-1af4-4f61-8180-5cd479bf96db">

11. **Event Details**: Clicking on an event opens a detailed view where all particulars are displayed, including the calculated total for each participant respective of the tax and tips.

<img width="1470" alt="event" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/34c9493e-bd94-4849-b932-30256f9a8bb1">

12. **Meal Search**: If opting to stay in and cook, users can search for recipes by entering a dish name in the search bar and pressing enter.

<img width="1470" alt="meal" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/88c822dd-46e0-42e4-866a-667007ef97fd">

13. **Exploring Dish Details**: The search reveals detailed information about the dish, including images, full name, category, are/origin, cooking instructions, tags, and a YouTube tutorial link.

<img width="1470" alt="explore" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/3dda34ef-782b-40e6-ac1c-c8429656da79">

14. **Discovering New Dishes:** To explore new recipes, click the "Random Dish" button.

<img width="1470" alt="discover" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/37da695c-9627-4c01-bc37-b4f5c85cd45f">

15. **Random Dish Display:** A random dish will appear, complete with comprehensive details.

<img width="1470" alt="random" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/d27e43d7-22c5-4e28-9fec-ccf61e2e4dc0">


16. **Additional Information:** Further scrolling provides more insights into the dish. Users can click the provided YouTube link to watch a cooking demonstration.

<img width="1470" alt="additional" src="https://github.com/lmu-cmsi2022-spring2024/your-own-dd/assets/112520530/bfb9b6d7-d383-4cea-877a-32399fcf257a">


**Technology Highlights**

Firebase Authentication: Manages user authentication processes.

Cloud Firestore: Stores and retrieves user events and associated participants, dishes, and expenses.

API: Utilizes external APIs to fetch dish recommendations.

• Model objects
• Abstraction of back-end functionality
• Feedback for operations-in-progress
• Error handling and messaging

• Professional finance inclined design and color palette
• Proper choice of input views and controls
• Animations and Transitions
• Programmed graphics

• Custom app icon


**Acknowledgements and Credits:**

ThemealDB for my API

Link to their website: <https://www.themealdb.com/api.php>

Rules for Cloud Firestore:

service cloud.firestore {

`  `match /databases/{database}/documents {

`    `// Matches any document in the 'events' collection

`    `match /events/{eventId} {

`      `// Allow read/write if the user is authenticated

`      `allow read, write: if request.auth != null;

`      `// Matches any document in the 'participants' sub-collection of an event

`      `match /participants/{participantId} {

`        `allow read, write: if request.auth != null;

`      `}

`      `// Matches any document in the 'dishes' sub-collection of an event

`      `match /dishes/{dishId} {

`        `allow read, write: if request.auth != null;

`      `}

`      `// Matches any document in the 'expenses' sub-collection of an event

`      `match /expenses/{expenseId} {

`        `allow read, write: if request.auth != null;

`      `}

`    `}

`  `}

}
