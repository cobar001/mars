import java.util.ArrayList;
import java.util.Random;

/**
 * Created by ChristopherCobar on 7/8/16.
 */
public class CardStack {

    private ArrayList<Card> cards;

    public CardStack() {

        this.cards = new ArrayList<>();

    }

    @Override
    public String toString() {

        String out = "| ";

        for (Card card: this.cards) {

            out += card.toString() + " | ";

        }

        return out;

    }

    public void push(Card c) { this.cards.add(c); }

    public Boolean isEmpty() { return this.cards.isEmpty(); }

    public Card pop() { return this.cards.remove(this.cards.size()-1); }

    public ArrayList getCards() { return this.cards; }

    //fisher-yates
    public void shuffle() {

        int index;
        Card temp;

        Random random = new Random();

        for (int i = this.cards.size()-1; i > 0; i--) {

            index = random.nextInt(i + 1);
            temp = this.cards.get(index);
            this.cards.set(index, this.cards.get(i));
            this.cards.set(i, temp);

        }

    }

    //insertion sort
    public void sort() {

        Card tempCard;
        ArrayList<Card> retStack;

        if (cards.get(0).getIsTraditional()) {

            retStack = new ArrayList<>();
            ArrayList<Card> tempStack;

            for (String suit : Game.suits) {

                tempStack = new ArrayList<>();

                for (Card c : cards) {

                    if (c.getSuit().equals(suit)) {

                        tempStack.add(c);

                    }

                }

                for (int i = 1; i < tempStack.size(); i++) {

                    for (int j = i; j > 0; j--) {

                        if (tempStack.get(j).compareTo(tempStack.get(j - 1)) < 1) {

                            tempCard = tempStack.get(j);
                            tempStack.set(j, tempStack.get(j - 1));
                            tempStack.set(j - 1, tempCard);

                        }

                    }

                }

                for (Card ca: tempStack) {

                    retStack.add(ca);

                }

            }

            this.cards = retStack;

        } else {

            for (int i = 1; i < this.cards.size(); i++) {

                for (int j = i; j > 0; j--) {

                    if (this.cards.get(j).compareTo(this.cards.get(j - 1)) < 1) {

                        tempCard = this.cards.get(j);
                        this.cards.set(j, this.cards.get(j - 1));
                        this.cards.set(j - 1, tempCard);

                    }

                }

            }

        }

    }

    /* not needed stack functions

    public Card peek() { return this.cards.get(this.cards.size()-1); }

    */

}
