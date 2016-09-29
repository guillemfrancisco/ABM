public interface Placeable {
    public PVector getPosition();
}


public abstract class Agent implements Placeable {

    protected int id;
    protected Roads map = null;
    protected boolean selected = false;
    
    protected PVector pos = new PVector();
    protected Node inNode = null,
                 toNode = null;
    protected float distTraveled = 0;
    protected Path path = new Path();
    
    protected int size;
    protected color tint;
    
    public Agent(int id, Roads map) {
        this.id = id;
        this.map = map;
        
        inNode = map.randomNode();
        pos = inNode.getPosition();
        toNode = findDestination();
        
    }
    
    
    public void setStyle(int size, String tint) {
        this.size = size;
        this.tint = unhex( "FF" + tint.substring(1) );
    }
    
    
    public PVector getPosition() {
        return pos.copy();
    }
    
    public boolean isSelected() {
        return selected;
    }
    
    public Node findDestination() {
        Node destination = null;
        while(true) {
            destination = map.randomNode();
            if( !destination.equals(inNode) && destination != null ) break;
        }
        return destination;
    }
    
    
    public void move(float speed) {
        if(!path.available()) path.findPath(map.getNodes(), inNode, toNode);
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
    
    
    public void draw() {
        
        if(selected) {
            path.draw(1, tint);
            
            textAlign(LEFT, CENTER); textSize(9);
            text( (int) distTraveled + "m", pos.x + 2 * size, pos.y);
            
            fill(tint, 75); noStroke();
            ellipse(pos.x, pos.y, 4 * size, 4 * size);
            
        }
        
        drawShape();

    }

    protected abstract void drawShape();
    
    public boolean select() {
        selected = dist(mouseX, mouseY, pos.x, pos.y) < size;
        return selected;
    }

}



public class Person extends Agent {

    Person(int id, Roads map) {
        super(id, map);
    }
    
    
    protected void drawShape() {
        fill(tint); noStroke();
        ellipse(pos.x, pos.y, size, size);
        text(toNode.id, pos.x, pos.y);
    }
    
}


public class Car extends Agent {
    
    Car(int id, Roads map) {
        super(id, map);
    }
    
    protected void drawShape() {
        fill(tint); noStroke(); rectMode(CENTER);
        rect(pos.x, pos.y, size, size);
    }
    
}