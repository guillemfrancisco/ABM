public interface Placeable {
    public PVector getPosition();
}


public class Agent implements Placeable {

    private int id;
    private Roads map = null;
    private boolean selected = false;
    
    private PVector pos = new PVector();
    private Node inNode = null,
                 toNode = null;
    private float distTraveled = 0;
    private Path path = new Path();
    
    private int dotSize;
    private color tint;
    
    public Agent(int id, Roads map) {
        this.id = id;
        this.map = map;
        
        inNode = map.randomNode();
        pos = inNode.getPosition();
        toNode = findDestination();
        
    }
    
    
    public void setStyle(int dotSize, String tint) {
        this.dotSize = dotSize;
        this.tint = unhex( "FF" + tint.substring(1) );
    }
    
    
    public PVector getPosition() {
        return pos.copy();
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
            text( (int) distTraveled + "m", pos.x + 2 * dotSize, pos.y);
            
            fill(tint, 75); noStroke();
            ellipse(pos.x, pos.y, 4 * dotSize, 4 * dotSize);
            
        }
        fill(tint); noStroke();
        ellipse(pos.x, pos.y, dotSize, dotSize);

    }
    
    
    public boolean select() {
        selected = dist(mouseX, mouseY, pos.x, pos.y) < dotSize;
        return selected;
    }

}