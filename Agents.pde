public interface Placeable {
    public PVector getPosition();
}



// AGENTS FACADE --------------->
public class Agents {

    private final PApplet PAPPLET;
    private final Roads ROADMAP;
    private final AgentFabric FABRIC = new AgentFabric();
    private ArrayList<Agent> agents = new ArrayList();
    
    
    public Agents(PApplet papplet, Roads roads) {
        PAPPLET = papplet;
        ROADMAP = roads;
    }
    
    
    public int count() {
        return agents.size();
    }
    
    
    public ArrayList<Agent> getAgents() {
        return agents;
    }
    
    
    public void loadFromJSON(String pathJSON) {
        File file = new File(dataPath(pathJSON));
        if( !file.exists() ) println("ERROR! JSON file does not exist");
        else agents.addAll( FABRIC.loadFromJSON(file, ROADMAP) );
    
    }
    
    
    public void move(float speed) {
        for(Agent agent : agents) agent.move(speed);
    }
    
    
    public void draw() {
        for(Agent agent : agents) agent.draw();
    }

    
    public void select(int mouseX, int mouseY) {
        for(Agent agent : agents) agent.select(mouseX, mouseY);
    }
    
    
    public void printLegend(int x, int y) {
        String txt = "";
        IntDict counter = FABRIC.getCounter();
        for(String name : counter.keyArray()) txt += name + ": " + counter.get(name) + " agents\n";
        text(txt, x, y);
    }

}



// AGENTS FABRIC --------------->
private class AgentFabric {

    IntDict counter = new IntDict();
    
    
    public IntDict getCounter() {
        return counter;
    }
    
    
    public ArrayList<Agent> loadFromJSON(File JSONFile, Roads roads) {

        ArrayList<Agent> agents = new ArrayList();
            
        JSONArray clusters = loadJSONObject(JSONFile).getJSONArray("clusters");
        for(int i = 0; i < clusters.size(); i++) {
            JSONObject cluster = clusters.getJSONObject(i);
            
            int id            = cluster.getInt("id");
            String name       = cluster.getString("name");
            String type       = cluster.getString("type");
            int amount        = cluster.getInt("amount");
            
            JSONObject style  = cluster.getJSONObject("style");
            String tint       = style.getString("color");
            int size          = style.getInt("size");
            
            for(int j = 0; j < amount; j++) {
                Agent agent = null;
                
                if(type.equals("PERSON")) agent = new Person(agents.size(), roads, size, tint);
                if(type.equals("CAR")) agent = new Car(agents.size(), roads, size, tint);
                
                if(agent != null) {
                    agents.add(agent);
                    counter.increment(name);
                }
                
            }
            
        }
    
        return agents;
    }
    
}







public abstract class Agent implements Placeable {

    public final int ID;
    protected final Roads ROADMAP;
    protected final int SIZE;
    protected final color COLOR;
    
    protected boolean selected = false;
    
    protected PVector pos = new PVector();
    protected Node inNode = null,
                 toNode = null;
    protected float distTraveled = 0;
    protected Path path = new Path();
    
    
    public Agent(int id, Roads map, int size, String hexColor) {
        ID = id;
        ROADMAP = map;
        SIZE = size;
        COLOR = unhex( "FF" + hexColor.substring(1) );
        
        inNode = map.randomNode();
        pos = inNode.getPosition();
        toNode = findDestination();
        
    }
    
    
    public PVector getPosition() {
        return pos.copy();
    }
    
    
    public Node findDestination() {
        Node destination = null;
        while(true) {
            destination = ROADMAP.randomNode();
            if( !destination.equals(inNode) ) break;
        }
        return destination;
    }
    
    
    public void move(float speed) {
        if(!path.available()) path.findPath(ROADMAP.getNodes(), inNode, toNode);
        else {
            if( !path.hasArrived() ) {
                PVector movement = path.move(pos, speed);
                pos.add( movement );
                distTraveled += movement.mag();
                inNode = path.inNode();
            } else {
                toNode = findDestination();
                path.clear();
            }
        }
    }
    
    
    public boolean select(int mouseX, int mouseY) {
        selected = dist(mouseX, mouseY, pos.x, pos.y) < SIZE;
        return selected;
    }
    
    
    public abstract void draw();

}



private class Person extends Agent {

    public Person(int id, Roads map, int size, String hexColor) {
        super(id, map, size, hexColor);
    }
    
    
    public void draw() {
        if(selected) {
            path.draw(1, COLOR);
            fill(COLOR, 75); noStroke();
            ellipse(pos.x, pos.y, 4 * SIZE, 4 * SIZE);
        }
        fill(COLOR); noStroke();
        ellipse(pos.x, pos.y, SIZE, SIZE);
    }

}



private class Car extends Agent {

    public Car(int id, Roads map, int size, String hexColor) {
        super(id, map, size, hexColor);
    }
    
    
    public void draw() {
        if(selected) {
            path.draw(1, COLOR);
            fill(COLOR, 75); noStroke();
            ellipse(pos.x, pos.y, 4 * SIZE, 4 * SIZE);
        }
        noFill(); stroke(COLOR); strokeWeight(1);
        ellipse(pos.x, pos.y, SIZE, SIZE);
    }

}