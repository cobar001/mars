MARS_LAB_Programming_README

When designing this little card simulation, I tried to only include the most necessary objects and methods
to reduce clutter. To begin, I created the Card object that consisted of properties that would later help when
implementing the main portion of the simulation (e.g. the suits and names to make output easy and specific
integer values for each specific card in their suit to help sorting). I also made the Card object relatively
versatile as it can be used as either a “numerical” card or a “traditional” playing card with suits, etc.

Continuing on, the next object I found necessary to create was the CardStack. The CardStack implemented
the basic fundamentals (LIFO, pop(), push(), etc.) of a general Stack, however, this was specially implemented
with the Card object in mind. When determining which Java object to use behind the scenes in order to store the
Cards, the options were either a LinkedList or an ArrayList. Although the LinkedList theoretically performs better
when adding/removing, I did not necessarily think that functionality would trump the benefits of the ArrayLists’
indexing optimization for the sorting and shuffling that would come later, so I used the ArrayList. Either way, both
options would have worked considering the scale at which the Lists would be used for.

The CardStack is also where the implementation of the sorting and shuffling algorithms were placed. When it
came to sorting, at this scale, most of the basic sorting algorithms would have likely performed adequately (quick sort,
heap sort, etc.). However, I decided to implement insertion sort because of its simplicity and considering the rather
small sorting size. As for shuffling, I decided to implement the Fisher-Yates shuffling algorithm as it is relatively simple,
efficient, and trusted (considering it is the method used by Java’s underlying sorting algorithm).

Finally, the main method is contained within the last object which is the Game class. The Game class contains some static,
constant properties that aid throughout the simulation in creating the decks and keeping track of card values/names.
I also decided to include a method to slightly delay the operations in the main simulation loop to create a more fluid experience
for the user. Other than that, each class has their own toString() methods that aid in the formatting of the output.

To run the program, Java 8 (JDK 8u91) is needed.
From there, the following command will begin execution
on the jar file in the root directory titled “MARS_assignment.jar”:

java -jar MARS_assignment.jar
