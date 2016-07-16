import org.junit.Assert;
import org.junit.Test;


/**
 * Created by ChristopherCobar on 7/9/16.
 */

public class CardTest {

    @Test
    public void getSuit() throws Exception {

        //Given
        String suit = "Hearts";
        String name = "King";
        Integer value = 13;
        Boolean isTraditional = true;

        //When
        Card card = new Card(suit, name, value, isTraditional);

        //Then
        Assert.assertTrue(card.getSuit().equals(suit));

    }

    @Test
    public void getIsTraditional() throws Exception {

        //Given
        String suit = "Hearts";
        String name = "King";
        Integer value = 13;
        Boolean isTraditional = true;

        //When
        Card card = new Card(suit, name, value, isTraditional);

        //Then
        Assert.assertTrue(card.getIsTraditional());

    }

    @Test
    public void compareTo() throws Exception {

        //Given
        String suit = "Hearts";
        String name = "King";
        Integer value = 13;
        Boolean isTraditional = true;

        String suit2 = "Hearts";
        String name2 = "Queen";
        Integer value2 = 12;
        Boolean isTraditional2 = true;

        //When
        Card card = new Card(suit, name, value, isTraditional);

        Card card2 = new Card(suit2, name2, value2, isTraditional2);

        //Then
        Assert.assertTrue(card.compareTo(card2) == 1);

    }

}

