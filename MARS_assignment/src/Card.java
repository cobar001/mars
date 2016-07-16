/**
 * Created by ChristopherCobar on 7/8/16.
 */


public class Card {

    private String suit;
    private String name;
    private Integer value;
    private Boolean isTraditional;

    public Card(String suit, String name, Integer value, Boolean isTraditional) {

        this.suit = suit;
        this.name = name;
        this.value = value;
        this.isTraditional = isTraditional;

    }

    public String getSuit() { return this.suit; }

    public Boolean getIsTraditional() { return this.isTraditional; }

    public int compareTo(Card c) {

        if (this.value > c.value) {
            return 1;
        } else if (this.value < c.value) {
            return -1;
        } else {
            return 0;
        }

    }

    public String toString() {

        if (this.isTraditional) {

            return this.name + " of " + this.suit;

        } else {

            return "Card " + this.name;

        }

    }

    /* not needed standard set/get functions

    public String getName() { return this.name; }
    public Integer getValue() { return this.value; }
    public void setSuit(String s) { this.suit = s; }
    public void setName(String n) { this.name = n; }
    public void setValue(Integer v) { this.value = v; }
    public void setIsTraditional(Boolean i) { this.isTraditional = i; }
    */

}
