// AGENTS FACADE --------------->
public class Agents extends Facade {
    
    public Agents(PApplet papplet, Roads roads) {
        super(papplet, roads);
        fabric = new AgentFabric();
    }

    
    public void move(float speed) {
        for(Placeable item : items) {
            Agent agent = (Agent) item;
            agent.move(speed);
        }
    }

}



// AGENTS FABRIC --------------->
private class AgentFabric extends Fabric {

    public ArrayList<Agent> loadFromJSON(File JSONFile, Roads roads) {

        ArrayList<Agent> agents = new ArrayList();
        int count = count();
        
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
                
                if(type.equals("PERSON")) agent = new Person(count, roads, size, tint);
                if(type.equals("CAR")) agent = new Car(count, roads, size, tint);
                
                if(agent != null) {
                    agents.add(agent);
                    counter.increment(name);
                    count++;
                }
            }
        }
        
        return agents;
    }
    
    
    public ArrayList<Agent> loadFromCSV(String pathCSV, Roads roadmap) {
        return null;
    }
    
}


// AGENTS CLASS ----------------->
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
        
        inNode = ROADMAP.randomNode();
        toNode = findDestination();
        pos = inNode.getPosition();
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
    
    
    public void select(int mouseX, int mouseY) {
        selected = dist(mouseX, mouseY, pos.x, pos.y) < SIZE;
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