public abstract class Facade {
    
    protected final PApplet PAPPLET;
    protected final Roads ROADMAP;
    protected Factory factory;
    protected ArrayList<Placeable> items = new ArrayList();
    
    public Facade(PApplet papplet, Roads roadmap) {
        PAPPLET = papplet;
        ROADMAP = roadmap;
    }
    
    public int count() {
        return items.size();
    }
    
    
    public <T> ArrayList<T> filter(Predicate<T> predicate) {
        ArrayList<T> result = new ArrayList();
        for(int i = 0; i < items.size(); i++) {
            T item = (T) items.get(i);
            if(predicate.evaluate(item)) result.add(item);
        }
        return result;
    }
    
    
    public ArrayList getAll() {
        return items;
    }
    
    
    public Placeable getRandom() {
        int i = round(random(0, items.size()-1));
        return items.get(i);
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
        else items.addAll( factory.loadFromJSON(file, ROADMAP) );
    
    }
    
    
    public void loadFromCSV(String path) {
        File file = new File( dataPath(path) );
        if( !file.exists() ) println("ERROR! CSV file does not exist");
        else items.addAll( factory.loadFromCSV(path, ROADMAP) );
    
    }
    
    
    public void printLegend(int x, int y) {
        String txt = "";
        IntDict counter = factory.getCounter();
        for(String name : counter.keyArray()) txt += name + ": " + counter.get(name) + "\n";
        text(txt, x, y);
    }
    
}


public abstract class Factory {
    
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