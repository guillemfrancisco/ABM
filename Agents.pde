// AGENTS FACADE --------------->
public class Agents extends Facade {
    
    private float speed;
    private float maxSpeed = 5; 
    
    public Agents(Roads roads) {
        super(roads);
        factory = new AgentFactory();
    }

    
    public void setSpeed(float _speed, float _maxSpeed) {
        maxSpeed = _maxSpeed;
        speed = constrain(_speed, 0, maxSpeed);
    }
    
    public void changeSpeed(float inc) {
        speed = constrain(speed + inc, 0, maxSpeed);
    }
    
    public float getSpeed() {
        return speed;
    }

    public void move() {
        for(Placeable item : items) {
            Agent agent = (Agent) item;
            agent.move(speed);
        }
    }

}



// AGENTS FACTORY --------------->
private class AgentFactory extends Factory {

    public ArrayList<Agent> loadFromJSON(File file, Roads roads) {

        ArrayList<Agent> agents = new ArrayList();
        int count = count();
        
        JSONArray clusters = loadJSONObject(file).getJSONArray("clusters");
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
    
    
    public ArrayList<Agent> loadFromCSV(String path, Roads roads) {
        return null;
    }
    
}


// AGENTS CLASS ----------------->
public abstract class Agent implements Placeable {

    public final int ID;
    protected final int SIZE;
    protected final color COLOR;
    
    protected int speedFactor = 1;
    protected int explodeSize = 0;
    protected int timer = 0;
    
    protected boolean selected = false;
    protected boolean arrived = false;
    protected boolean panicMode = false;
    
    protected POI destination;
    protected PVector pos;
    protected Path path;
    protected Node inNode;
    protected float distTraveled;
    
    
    public Agent(int id, Roads roads, int size, String hexColor) {
        ID = id;
        SIZE = size;
        COLOR = unhex( "FF" + hexColor.substring(1) );

        path = new Path(this, roads);
        place(roads);
        destination = findDestination();
        
    }
    
    
    public int getID() {
        return ID;
    }
    
    
    public PVector getPosition() {
        return pos.copy();
    }
    
    
    public POI findDestination() {
        POI newDestination = null;
        arrived = false;
        path.reset();
        while(newDestination == null || inNode.equals(newDestination.getNode())) {
            newDestination = (POI)pois.getRandom();
        }
        return newDestination;
    }
    
    
    public void move(float speed) {
        if(!arrived) {
            if(!path.available()) panicMode = !path.findPath(inNode, destination.getNode());
            else {
                PVector movement = path.move(pos, speed * speedFactor);
                pos.add( movement );
                distTraveled += movement.mag();
                inNode = path.inNode();
                if(path.hasArrived()) {
                    arrived = true;
                    whenArrived();
                }
            }
        } else inPlace();
    }
    
    
    public boolean isMoving() {
        return !arrived;
    }
    
    
    public void select(int mouseX, int mouseY) {
        selected = dist(mouseX, mouseY, pos.x, pos.y) < SIZE;
        if(selected) {
            println(this);
        }
    }
    
    
    protected void drawPanic() {
        fill(#FF0000, 50); noStroke();
        explodeSize = (explodeSize + 1)  % 30;
        ellipse(pos.x, pos.y, explodeSize, explodeSize);
    }
    
    
    public String toString() {
        String goingTo = destination != null ? "GOING TO " + destination + " THROUGH " + path.toString() : "ARRIVED";
        return "AGENT " + ID + " " + goingTo;
    }
    
    
    protected void wander() {
        float offset = arrived ? destination.getSize()/2 : 5;
        pos = inNode.getPosition().add( PVector.random2D().mult( random(0, offset)) );
    }
    
    
    public abstract void draw();
    protected abstract void whenArrived();
    protected abstract void inPlace();
    
}



private class Person extends Agent {

    public Person(int id, Roads map, int size, String hexColor) {
        super(id, map, size, hexColor);
    }
    
    
    public void place(Roads roads) {
        inNode = roads.randomNode();
        pos = inNode.getPosition();
    }
    
    
    public void draw() {
        if(selected) {
            path.draw(1, COLOR);
            fill(COLOR, 75); noStroke();
            ellipse(pos.x, pos.y, 4 * SIZE, 4 * SIZE);
            //fill(0);
            //text(round(distTraveled) + "/" + round(path.getLength()), pos.x, pos.y);
        }
        
        if(panicMode) {
            drawPanic();
            PVector destPos = destination.getPosition();
            stroke(#FF0000, 100); strokeWeight(1);
            line(pos.x, pos.y, destPos.x, destPos.y);
        }
        
        fill(COLOR); noStroke();
        ellipse(pos.x, pos.y, SIZE, SIZE);
    }


    protected void whenArrived() {
        if(!destination.host(this)) {
            destination = findDestination();
        } else {
            timer = millis();
            panicMode = true;
        }
    }


    protected void inPlace() {
        wander();
        if(millis() - timer > 2000) {
            panicMode = false;
            destination.unhost(this);
            destination = findDestination();
        }
    }

}



private class Car extends Agent {
    
    public Car(int id, Roads map, int size, String hexColor) {
        super(id, map, size, hexColor);
        speedFactor = 3;
    }
    
    
    public void place(Roads roads) {
        inNode = roads.randomNode();
        pos = inNode.getPosition();
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
    
    
    protected void whenArrived() {
        if(!destination.host(this)) {
            destination = findDestination();
        }
    }
    
    protected void inPlace() {}

}