import junit.framework.TestCase;
import org.junit.Assert;


/**
 * Created by ChristopherCobar on 7/9/16.
 */

public class CardStackTest extends TestCase {

    public void testPush() throws Exception {

        //Given
        String suit = "Hearts";
        String name = "King";
        Integer value = 13;
        Boolean isTraditional = true;

        //When
        CardStack deck = new CardStack();
        Card card = new Card(suit, name, value, isTraditional);
        deck.push(card);

        //Then
        Assert.assertTrue(deck.getCards().contains(card));

    }

    public void testIsEmpty() throws Exception {

        //When
        CardStack deck = new CardStack();

        //Then
        Assert.assertTrue(deck.getCards().isEmpty());

    }

    public void testPop() throws Exception {

        //Given
        String suit = "Hearts";
        String name = "King";
        Integer value = 13;
        Boolean isTraditional = true;

        //When
        CardStack deck = new CardStack();
        Card card = new Card(suit, name, value, isTraditional);
        deck.push(card);

        //Then
        Assert.assertTrue(deck.pop().equals(card));
        Assert.assertTrue(deck.isEmpty());

    }

    public void testShuffle() throws Exception {

        //Given
        String suit = "Hearts";
        String name = "King";
        Integer value = 13;
        Boolean isTraditional = true;

        String suit2 = "Diamonds";
        String name2 = "Queen";
        Integer value2 = 12;
        Boolean isTraditional2 = true;

        String suit3 = "Clubs";
        String name3 = "10";
        Integer value3 = 10;
        Boolean isTraditional3 = true;

        //When
        CardStack deck = new CardStack();
        Card card = new Card(suit, name, value, isTraditional);
        Card card2 = new Card(suit2, name2, value2, isTraditional2);
        Card card3 = new Card(suit3, name3, value3, isTraditional3);

        deck.push(card);deck.push(card2);deck.push(card3);

        CardStack deck2 = deck;

        deck.shuffle();

        //Then
        Assert.assertTrue(deck.getCards().size() == deck2.getCards().size());

    }

    public void testSort() throws Exception {

        //Given
        String suit = "Hearts";
        String name = "King";
        Integer value = 13;
        Boolean isTraditional = true;

        String suit2 = "Diamonds";
        String name2 = "Queen";
        Integer value2 = 12;
        Boolean isTraditional2 = true;

        String suit3 = "Clubs";
        String name3 = "10";
        Integer value3 = 10;
        Boolean isTraditional3 = true;

        //When
        CardStack deck = new CardStack();
        Card card = new Card(suit, name, value, isTraditional);
        Card card2 = new Card(suit2, name2, value2, isTraditional2);
        Card card3 = new Card(suit3, name3, value3, isTraditional3);

        deck.push(card);deck.push(card2);deck.push(card3);

        CardStack sortedDeck = new CardStack();
        sortedDeck.push(card3);sortedDeck.push(card2);sortedDeck.push(card);

        deck.sort();

        //Then
        Assert.assertTrue(sortedDeck.getCards().equals(deck));

    }

}
