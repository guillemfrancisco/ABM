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
    
    public int size() {
        return lanes.size();
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
        //PVector destVertex = currentLane.getVertex( toVertex );
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


    public void clear() {
        lanes = new ArrayList();
        inNode = null;
        distance = 0;
        arrived = false;
        
        currentLane = null;
        toVertex = null;
    }
    
    
    public boolean findPath(Node origin, Node destination) {
        if(origin != null && destination != null) {
            clear();
            inNode = origin;
            ArrayList<Node> pathNodes = aStar(ROADMAP.getNodes(), origin, destination);
            
            if(pathNodes.size() == 0) return false;
            
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
        return false;
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