public interface Placeable {
    public PVector getPosition();
    public void select(int mouseX, int mouseY);
    public void draw();
}

public abstract class Facade {
    
    protected final PApplet PAPPLET;
    protected final Roads ROADMAP;
    protected Fabric fabric;
    protected ArrayList<Placeable> items = new ArrayList();
    
    public Facade(PApplet papplet, Roads roadmap) {
        PAPPLET = papplet;
        ROADMAP = roadmap;
    }
    
    public int count() {
        return items.size();
    }
    
    
    public ArrayList getItems() {
        return items;
    }
    
    
    public Placeable getRandom() {
        return items.get( (int) random(0, items.size() ) );
    }
    
    
    public void draw() {
        for(Placeable item : items) item.draw();
    }
    
    
    public void select(int mouseX, int mouseY) {
        for(Placeable item : items) item.select(mouseX, mouseY);
    }

    
    public void loadFromJSON(String path) {
        File file = new File( dataPath(path) );
        if( !file.exists() ) println("ERROR! JSON file does not exist");
        else items.addAll( fabric.loadFromJSON(file, ROADMAP) );
    
    }
    
    
    public void loadFromCSV(String path) {
        File file = new File( dataPath(path) );
        if( !file.exists() ) println("ERROR! CSV file does not exist");
        else items.addAll( fabric.loadFromCSV(path, ROADMAP) );
    
    }
    
    
    public void printLegend(int x, int y) {
        String txt = "";
        IntDict counter = fabric.getCounter();
        for(String name : counter.keyArray()) txt += name + ": " + counter.get(name) + "\n";
        text(txt, x, y);
    }
    
}


public abstract class Fabric {
    
    protected IntDict counter = new IntDict();
    
    public IntDict getCounter() {
        return counter;
    }
    
    public int count() {
        int count = 0;
        for(String name : counter.keyArray()) count += counter.get(name);
        return count;
    }
    
    public abstract ArrayList loadFromJSON(File file, Roads roads);
    public abstract ArrayList loadFromCSV(String path, Roads roads);
    
}