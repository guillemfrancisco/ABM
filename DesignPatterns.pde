/**
* Agents - Abstract Facade to simplify manipulation of items in simulation
* @author        Marc Vilella
* @version       1.0
* @see           Factory
*/
public abstract class Facade {
    
    protected PApplet parent;
    protected Factory factory;
    protected ArrayList<Placeable> items = new ArrayList();
    
    
    /**
    * Initiate Facade to work with specific roadmap
    * @param parent  Sketch applet, just put this when calling constructor
    */
    public Facade(PApplet parent) {
        this.parent = parent;
    }
    
    
    /**
    * Count the total amount of items
    * @return amount of items in facade
    */
    public int count() {
        return items.size();
    }
    
    
    /**
    * Count the amount of items that match with a specific condition
    * @param predicate  Predicate condition
    * @return amount of items matching with condition
    */
    public <T> int count(Predicate<T> predicate) {
        return filter(predicate).size();
    }
    
    
    /**
    * Filter items by a specific condition
    * @param predicate  Predicate condition
    * @return list of all items matching with condition
    */
    public <T> ArrayList<T> filter(Predicate<T> predicate) {
        ArrayList<T> result = new ArrayList();
        for(int i = 0; i < items.size(); i++) {
            T item = (T) items.get(i);
            if(predicate.evaluate(item)) result.add(item);
        }
        return result;
    }
    
    
    /**
    * Get all items
    * @return list with all items
    */
    public ArrayList getAll() {
        return items;
    }
    
    
    /**
    * Get a random item
    * @return random item
    */
    public Placeable getRandom() {
        int i = round(random(0, items.size()-1));
        return items.get(i);
    }
    
    
    /** 
    * Draw all items
    */
    public void draw() {
        for(Placeable item : items) item.draw();
    }
    
    
    /**
    * Select items that are under mouse pointer
    * @param mouseX  Horizontal mouse position in screen
    * @param mouseY  Vertical mouse position in screen
    */
    public void select(int mouseX, int mouseY) {
        for(Placeable item : items) item.select(mouseX, mouseY);
    }

    
    /**
    * Create new items from a JSON file, if it exists
    * @param path  Path to JSON file with items definitions
    * @param roads  Roadmap where objects will be added
    */
    public void loadJSON(String path, Roads roadmap) {
        File file = new File( dataPath(path) );
        if( !file.exists() ) println("ERROR! JSON file does not exist");
        else items.addAll( factory.loadJSON(file, roadmap) );
    }
    
    
    /**
    * Create new items from a CSV file, if it exists
    * @param path  Path to CSV file with items definitions
    * @param roads  Roadmap where objects will be added
    */
    public void loadCSV(String path, Roads roadmap) {
        File file = new File( dataPath(path) );
        if( !file.exists() ) println("ERROR! CSV file does not exist");
        else items.addAll( factory.loadCSV(path, roadmap) );
    
    }
    
    
    /**
    * Print item's legend in a specific position
    * @param x  Horizontal position in screen
    * @param y  Vertical position in screen
    */
    public void printLegend(int x, int y) {
        String txt = "";
        IntDict counter = factory.getCounter();
        for(String name : counter.keyArray()) txt += name + ": " + counter.get(name) + "\n";
        text(txt, x, y);
    }
    
}




/**
* Factory - Abstract Factory class to generate items from diferent sources 
* @author        Marc Vilella
* @version       1.0
*/
public abstract class Factory {
    
    protected IntDict counter = new IntDict();
    
    /**
    * Get items counter (dictionary with different type and total amount for each one)
    * @return items counter
    */
    public IntDict getCounter() {
        return counter;
    }
    
    
    /**
    * Count the total amount of objects created
    * @return amount of objects
    */
    public int count() {
        int count = 0;
        for(String name : counter.keyArray()) count += counter.get(name);
        return count;
    }
    
    
    /**
    * Create objects from a JSON file
    * @param file  JSON file with object definitions
    * @param roads  Roadmap where objects will be added
    * @return list with new created objects 
    */
    public abstract ArrayList loadJSON(File file, Roads roads);
    
    
    /**
    * Create objects form CSV file
    * @param path  Path to CSV file with object definitions
    * @param roads  Roadmap where objects will be added
    * @return list with new created object 
    */
    public abstract ArrayList loadCSV(String path, Roads roads);
    
}