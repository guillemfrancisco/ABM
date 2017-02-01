public class Path {

    private ArrayList<Lane> lanes = new ArrayList();
    private float length = 0;
    
    private Node inNode = null;
    private Lane lane;
    private int toVertex;
    
    private boolean arrived = false;
    
    public Path() {}
    

    public boolean available() { return getLength() > 1; }
    public int size() { return lanes.size(); }
    public float getLength() { return length; }
    public boolean hasArrived() { return arrived; }
    
    public Node inNode() { return inNode; }
    
    public void nextLane() {
        inNode = lane.getFinalNode();
        int nextLane = lanes.indexOf(lane) + 1;
        if( nextLane < lanes.size() ) {
            lane = lanes.get(nextLane);
            toVertex = 1;
        } else arrived = true;
    }
    
    
    public PVector move(PVector pos, float speed) {
        PVector vertex = lane.getVertex( toVertex );
        PVector dir = PVector.sub(vertex, pos);
        PVector movement = dir.copy().normalize().mult(speed);
        if(dir.mag() > movement.mag()) return movement;
        else {
            if( lane.isLastVertex( vertex ) ) nextLane();
            else toVertex++;
            return dir;
        }
    }
    
    
    public void draw(int stroke, color c) {
        for(Lane lane : lanes) {
            lane.draw(stroke, c);
        }
    }


    public void clear() {
        lanes = new ArrayList();
        inNode = null;
        length = 0;
        arrived = false;
        
        lane = null;
        toVertex = 0;
    }
    
    
    public void findPath(ArrayList<Node> graph, Node origin, Node destination) {
        if(origin != null && destination != null) {
            clear();
            inNode = origin;
            ArrayList<Node> pathNodes = aStar(graph, origin, destination);
            for(int i = 1; i < pathNodes.size(); i++) {
                Lane edge = pathNodes.get(i-1).shortestLaneTo(pathNodes.get(i));
                lanes.add(edge);
                length += edge.getLength();
            }
            
            if(lanes.size() > 0) {
                lane = lanes.get(0);
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
                for(Lane lane : currentNode.outboundLanes()) {
                    Node neighbor = lane.getFinalNode();
                    if( !lane.isOpen() || closed.contains(neighbor)) continue;
                    boolean neighborOpen = open.contains(neighbor);
                    float costToNeighbor = currentNode.getG() + lane.getLength();
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