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

    
    public float getLength() {
        return distance;
    }
    
    
    public boolean hasArrived() {
        return arrived;
    }
    
    
    public Node inNode() {
        return inNode;
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


    public void reset() {
        lanes = new ArrayList();
        inNode = null;
        distance = 0;
        arrived = false;
        
        currentLane = null;
        toVertex = null;
    }
    
    
    public boolean findPath(Node origin, Node destination) {
        if(origin != null && destination != null) {
            reset();
            inNode = origin;
            ArrayList<Node> pathNodes = aStar(origin, destination);
            if(pathNodes.size() > 0) {
                for(int i = 1; i < pathNodes.size(); i++) {
                    Lane lane = pathNodes.get(i-1).shortestLaneTo(pathNodes.get(i));
                    lanes.add(lane);
                    distance += lane.getLength();
                }
                if(lanes.size() > 0) {
                    currentLane = lanes.get(0);
                    toVertex = currentLane.getVertex(1);
                }
                return true;
            }
        }
        return false;
    }
    
    
    private ArrayList<Node> aStar(Node origin, Node destination) {
        ArrayList<Node> path = new ArrayList();
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
            path = retracePath(destination);
        } else println("BOTH EQUALS");
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