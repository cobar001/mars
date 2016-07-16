import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

/**
 * Created by ChristopherCobar on 7/8/16.
 */
public class Game {

    public static void main(String args[]) {

        System.out.print("Hello, choose which deck to use. ");
        System.out.print("\n[1] for numerical or [2] for traditional: ");
        Scanner initialChoiceScan = new Scanner(System.in);
        String dt = initialChoiceScan.nextLine();

        while (!dt.equals("1") && !dt.equals("2")) {
            System.out.print("\nPlease enter a valid deck type: ");
            dt = initialChoiceScan.nextLine();
        }

        CardStack deck = createDeck(deckTypes.get(dt));
        CardStack hand = new CardStack();

        boolean didQuit = false;

        while (!didQuit) {

            System.out.println("\nChoose an option: " +
                    "\n1. Draw a card to hand" +
                    "\n2. Place a card in hand on deck" +
                    "\n3. Shuffle the deck" +
                    "\n4. Sort the deck" +
                    "\n5. Print cards that exist in hand" +
                    "\n6. Print cards that exist in deck" +
                    "\n7. Quit");

            System.out.print("\nEnter choice: ");
            Scanner secondChoiceScan = new Scanner(System.in);
            String choice = secondChoiceScan.nextLine();

            while (!dt.equals("1") && !dt.equals("2") && !dt.equals("3")
                    && !dt.equals("4") && !dt.equals("5") && !dt.equals("6")
                    && !dt.equals("7")) {

                System.out.print("\nPlease enter a valid option: ");
                choice = initialChoiceScan.nextLine();

            }

            switch (choice) {

                case "1":

                    if (!deck.isEmpty()) {

                        Card draw = deck.pop();
                        hand.push(draw);
                        System.out.println("\n" + draw + " drawn");
                        briefPause(1);

                    } else {

                        System.out.println("\ndeck is empty!");
                        briefPause(1);

                    }

                    break;

                case "2":

                    if (!hand.isEmpty()) {

                        Card place = hand.pop();
                        deck.push(place);
                        System.out.println("\n"+ place + " placed on deck, from hand.");
                        briefPause(1);

                    } else {

                        System.out.println("\nno cards remaining in hand.");
                        briefPause(1);

                    }

                    break;

                case "3":

                    if (!deck.isEmpty()) {

                        deck.shuffle();
                        System.out.println("\ndeck shuffled.");
                        briefPause(1);

                    } else {

                        System.out.println("\nno cards remaining in deck.");
                        briefPause(1);

                    }

                    break;

                case "4":

                    if (!deck.isEmpty()) {

                        deck.sort();
                        System.out.println("\ndeck sorted.");
                        briefPause(1);

                    } else {

                        System.out.println("\nno cards remaining in deck.");
                        briefPause(1);

                    }

                    break;

                case "5":

                    if (!hand.isEmpty()) {

                        System.out.println("\ncards in hand: ");
                        System.out.println(hand);
                        briefPause(1);

                    } else {

                        System.out.println("\nno cards remaining in hand.");
                        briefPause(1);

                    }

                    break;

                case "6":

                    if (!deck.isEmpty()) {

                        System.out.println("\ncards in deck: ");
                        System.out.println(deck);
                        briefPause(1);

                    } else {

                        System.out.println("\nno cards remaining in deck.");
                        briefPause(1);

                    }

                    break;

                case "7":

                    System.out.println("\nQuitting ..\n");
                    briefPause(1);
                    didQuit = true;

                    break;

                default:

                    System.out.println("case missed");

            }

        }

    }

    public static final ArrayList<String> suits;
    static {

        suits = new ArrayList<>();
        suits.add("Hearts");suits.add("Spades");
        suits.add("Diamonds");suits.add("Clubs");

    }

    private static final Map<Integer, String> traditional;
    static {

        traditional = new HashMap<Integer, String>();
        traditional.put(2,"2");traditional.put(3,"3");traditional.put(4,"4");traditional.put(5,"5");
        traditional.put(6,"6");traditional.put(7,"7");traditional.put(8,"8");traditional.put(9,"9");
        traditional.put(10,"10");traditional.put(11,"Jack");traditional.put(12,"Queen");
        traditional.put(13,"King");traditional.put(14,"Ace");

    }

    private static final Map<String, String> deckTypes;
    static {

        deckTypes = new HashMap<String, String>();
        deckTypes.put("1","numerical");
        deckTypes.put("2","traditional");

    }

    private static CardStack createDeck(String deckType) {

        CardStack doneDeck = new CardStack();

        if (deckType.equals("traditional")) {

            for (String suit : suits) {

                for (int i = 2; i < 15; i++) {

                    Card newCard = new Card(suit, traditional.get(i), i, true);
                    doneDeck.push(newCard);

                }

            }

        } else {

            for (Integer i = 0; i < 60; i++) {


                Card newCard = new Card("N/A", i.toString(), i, false);
                doneDeck.push(newCard);

            }

        }

        return doneDeck;

    }

    //brief pause for easier UX flow
    public static void briefPause(int s) {

        try {

            Thread.sleep(s * 1000);

        }

        catch (InterruptedException e) {

            e.printStackTrace();

        }

    }

}
