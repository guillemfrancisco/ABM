public class Path {

    private ArrayList<Street> streets = new ArrayList();
    private float length = 0;
    
    private Node inNode = null;
    private Street street;
    private int toVertex;
    
    private boolean arrived = false;
    
    public Path() {}
    

    public boolean available() { return getLength() > 1; }
    public int size() { return streets.size(); }
    public float getLength() { return length; }
    public boolean hasArrived() { return arrived; }
    
    public Node inNode() { return inNode; }
    
    public void nextStreet() {
        inNode = street.getNode();
        int nextStreet = streets.indexOf(street) + 1;
        if( nextStreet < streets.size() ) {
            street = streets.get(nextStreet);
            toVertex = 1;
        } else arrived = true;
    }
    
    
    public PVector move(PVector pos, float speed) {
        PVector vertex = street.getVertex( toVertex );
        PVector dir = PVector.sub(vertex, pos);
        PVector movement = dir.copy().normalize().mult(speed);
        if(dir.mag() > movement.mag()) return movement;
        else {
            if( street.isLast( vertex ) ) nextStreet();
            else toVertex++;
            return dir;
            
            /*
            toStreetPoint++;
            if( toStreetPoint >= inStreet.size() ) nextStreet();
            return dir;
            */
        }
    }
    
    
    public void draw(int stroke, color c) {
        for(Street edge : streets) edge.draw(stroke, c);
        /*
        if( available() ) {
            PVector lastPos = edges.get( edges.size()-1 ).getNode().getPosition();
            textAlign(CENTER, BOTTOM); fill(c);
            text(length, lastPos.x, lastPos.y - 5);
        }
        */
    }


    public void clear() {
        streets = new ArrayList();
        inNode = null;
        length = 0;
        arrived = false;
        
        street = null;
        toVertex = 0;
    }
    
    
    public void findPath(ArrayList<Node> graph, Node origin, Node destination) {
        if(origin != null && destination != null) {
            clear();
            inNode = origin;
            ArrayList<Node> pathNodes = aStar(graph, origin, destination);
            for(int i = 1; i < pathNodes.size(); i++) {
                Street edge = pathNodes.get(i-1).streetTo(pathNodes.get(i));
                streets.add(edge);
                length += edge.getLength();
            }
            
            if(streets.size() > 0) {
                street = streets.get(0);
                toVertex = 1;
            }
        }
    }
    
    
    public ArrayList aStar(ArrayList<Node> nodes, Node origin, Node destination) {

        ArrayList<Node> path = new ArrayList(); 
        
        if(origin != destination) {
            
            for(Node node : nodes) node.reset();
            
            ArrayList<Node> open = new ArrayList();
            ArrayList<Node> closed = new ArrayList();
            
            open.add(origin);
            
            while(open.size() > 0) {
                
                float lowestF = Float.MAX_VALUE;
                Node currentNode = null;
                for(Node node : open) {
                    if(node.getF() < lowestF) {
                        lowestF = node.getF();
                        currentNode = node;
                    }
                }
                
                open.remove(currentNode);
                closed.add(currentNode);
                
                if(currentNode == destination) break;
                
                for(Street street : currentNode.outboundStreets()) {
                    Node neighbor = street.getNode();
                    
                    if( !street.isOpen() || closed.contains(neighbor)) continue;
                    
                    boolean neighborOpen = open.contains(neighbor);
                    float costToNeighbor = currentNode.getG() + street.getLength();
                    if( costToNeighbor < neighbor.getG() || !neighborOpen ) {
                        neighbor.setParent(currentNode); 
                        neighbor.setG(costToNeighbor);
                        neighbor.setF(destination);
                        if(!neighborOpen) open.add(neighbor);
                    }
                }
                
            }
            
            path = retracePath(destination);
        }
        
        return path;
    }
    
    
    private ArrayList<Node> retracePath(Node destination) {
        ArrayList<Node> path = new ArrayList();
        Node pathNode = destination;
        while(pathNode != null) {
          path.add(pathNode);
          pathNode = pathNode.getParent();
        }
        Collections.reverse(path);
        return path;
    }
    
    
    
}