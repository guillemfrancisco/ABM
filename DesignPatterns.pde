public interface Placeable {
    public PVector getPosition();
}


public interface MapItem {
    public void select(int mouseX, int mouseY);
    public void draw();
}


public abstract class Facade {
    
    protected final PApplet PAPPLET;
    protected final Roads ROADMAP;
    protected Fabric fabric;
    ArrayList<MapItem> items = new ArrayList();
    
    public Facade(PApplet papplet, Roads roadmap) {
        PAPPLET = papplet;
        ROADMAP = roadmap;
    }
    
    public int count() {
        return items.size();
    }
    
    
    public ArrayList get() {
        return items;
    }
    
    
    public void draw() {
        for(MapItem item : items) item.draw();
    }
    
    
    public void select(int mouseX, int mouseY) {
        for(MapItem item : items) item.select(mouseX, mouseY);
    }

    
    public void loadFromJSON(String pathJSON) {
        File file = new File( dataPath(pathJSON) );
        if( !file.exists() ) println("ERROR! JSON file does not exist");
        else items.addAll( fabric.loadFromJSON(file, ROADMAP) );
    
    }
    
    
    public void loadFromCSV(String pathCSV) {
        File file = new File( dataPath(pathCSV) );
        if( !file.exists() ) println("ERROR! JSON file does not exist");
        else items.addAll( fabric.loadFromCSV(pathCSV, ROADMAP) );
    
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
    
    public abstract ArrayList loadFromJSON(File JSONFile, Roads roads);
    public abstract ArrayList loadFromCSV(String pathTSV, Roads roads);
    
}