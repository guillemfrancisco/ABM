public class Path {

    private final Roads ROADMAP; 
    private final Agent AGENT;
    
    private ArrayList<Lane> lanes = new ArrayList();
    private float distance = 0;
    
    private Node inNode = null;
    private Lane currentLane;
    private PVector toVertex;
    
    private boolean arrived = false;
    
    public Path(Roads roadmap, Agent agent) {
        ROADMAP = roadmap;
        AGENT = agent;
    }
    

    public boolean available() {
        return lanes.size() > 0;
    }    

    
    private float computeLength() {
        float distance = 0;
        for(Lane lane : lanes) distance += lane.getLength();
        return distance;
    }
    
    
    public float getLength() {
        return distance;
    }
    
    
    public boolean hasArrived() {
        return arrived;
    }
    
    
    public Node inNode() {
        return inNode;
    }
    
    
    public void reset() {
        lanes = new ArrayList();
        currentLane = null;
        distance = 0;
    }
    
    
    public void nextLane() {
        inNode = currentLane.getFinalNode();
        currentLane.removeAgent(AGENT);
        int i = lanes.indexOf(currentLane) + 1;
        if( i < lanes.size() ) {
            currentLane = lanes.get(i);
            toVertex = currentLane.getVertex(1);
            currentLane.addAgent(AGENT);
        } else arrived = true;
    }
    
    
    public PVector move(PVector pos, float speed) {
        PVector dir = PVector.sub(toVertex, pos);
        PVector movement = dir.copy().normalize().mult(speed);
        if(dir.mag() > movement.mag()) return movement;
        else {
            if( currentLane.isLastVertex( toVertex ) ) nextLane();
            else toVertex = currentLane.nextVertex(toVertex);
            return dir;
        }
    }
    
    
    public void draw(int stroke, color c) {
        for(Lane lane : lanes) {
            lane.draw(stroke, c);
        }
    }
    
    public boolean findPath(Node origin, Node destination) {
        if(origin != null && destination != null) {
            lanes = aStar(origin, destination);
            if(lanes.size() > 0) {
                distance = computeLength();
                inNode = origin;
                currentLane = lanes.get(0);
                toVertex = currentLane.getVertex(1);
                arrived = false;
                return true;
            }
        }
        return false;
    }
    
    
    private ArrayList<Lane> aStar(Node origin, Node destination) {
        ArrayList<Lane> path = new ArrayList();
        if(!origin.equals(destination)) {
            for(Node node : ROADMAP.getNodes()) node.reset();
            ArrayList<Node> closed = new ArrayList();
            PriorityQueue<Node> open = new PriorityQueue();
            open.add(origin);
            while(open.size() > 0) {
                Node currNode = open.poll();
                closed.add(currNode);
                if( currNode.equals(destination) ) break;
                for(Lane lane : currNode.outboundLanes()) {
                    Node neighbor = lane.getFinalNode();
                    if( !lane.isOpen() || closed.contains(neighbor) ) continue;
                    boolean neighborOpen = open.contains(neighbor);
                    float costToNeighbor = currNode.getG() + lane.getLength();
                    if( costToNeighbor < neighbor.getG() || !neighborOpen ) {
                        neighbor.setParent(currNode); 
                        neighbor.setG(costToNeighbor);
                        neighbor.setF(destination);
                        if(!neighborOpen) open.add(neighbor);
                    }
                }
            }
            path = tracePath(destination);
        }
        return path;
    }
    
    
    private ArrayList<Lane> tracePath(Node destination) {
        ArrayList<Lane> path = new ArrayList();
        Node pathNode = destination;
        while(pathNode.getParent() != null) {
            path.add( pathNode.getParent().shortestLaneTo(pathNode) );
            pathNode = pathNode.getParent();
        }
        Collections.reverse(path);
        return path;
    }
    
    
}