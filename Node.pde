private class Node implements Placeable {

    private int id;
    protected PVector pos;
    private ArrayList<Lane> lanes = new ArrayList();
    private boolean selected;
    
    // Pathfinding variables
    private Node parent;
    private float f;
    private float g;
    private float h;
    
    public Node(PVector _pos) {
        id = -1;
        pos = _pos;
    }
    
    public int getID() {
        return id;
    }
    
    public void register(ArrayList<Node> nodes) {
        if(id == -1) {
            id = nodes.size();
            nodes.add(this);
        }
    }
    
    public PVector getPosition() {
        return pos.copy();
    }
    
    public ArrayList<Lane> outboundLanes() {
        return lanes;
    }
    
    public Lane shortestLaneTo(Node node) {
        Float shortestLaneLength = Float.NaN;
        Lane shortestLane = null;
        for(Lane lane : outboundLanes()) {
            if(node.equals(lane.getFinalNode())) {
                if(shortestLaneLength.isNaN() || lane.getLength() < shortestLaneLength) {
                    shortestLaneLength = lane.getLength();
                    shortestLane = lane;
                }
            }
        }
        return shortestLane;
    }
    
    
    public ArrayList<Node> getNeighborNodes() {
        ArrayList<Node> neighborNodes = new ArrayList();
        for(Lane lane : outboundLanes()) neighborNodes.add( lane.getFinalNode() );
        return neighborNodes;
    }
    
    
    public void disconnect(Node node) {
        for(Lane lane : outboundLanes()) {
            if( node.equals(lane.getFinalNode()) ) outboundLanes().remove(lane);
        }
    }
    
    
    /* PATHFINDING METHODS */
    public void setParent(Node _parent) { parent = _parent; }
    public Node getParent() { return parent; }
    public void setG(float _g) { g = _g; }
    public float getG() { return g; }
    public void setF(Node destination) {
        h =  pos.dist(destination.getPosition());
        f = g + h;
    }
    public float getF() { return f; }
    public float getH() { return h; }
    public void reset() {
        parent = null;
        f = g = h = 0.0;
    }
    
    
    protected void connect(Node node, ArrayList<PVector> vertices, String name) {
        lanes.add( new Lane(name, this, node, vertices) );
    }
    
    
    protected void connectBoth(Node node, ArrayList<PVector> vertices, String name) {
        connect(node, vertices, name);
        if(vertices != null) Collections.reverse(vertices);
        node.connect(this, vertices, name);
    }
    
    public void draw() {
        stroke(#000000);
        point(pos.x, pos.y);
    }
    
    public void draw(int stroke, color c) {
        for(Lane lane : lanes) {
            lane.draw(stroke, c);
        }
    }
    
    public void draw(Node n, int stroke, color c) {
        Lane lane = shortestLaneTo(n);
        lane.draw(stroke, c);
        PVector nextPos = lane.getFinalNode().getPosition();
        textAlign(LEFT, CENTER); textSize(9); fill(#990000);
        text(lane.getLength(), nextPos.x + 5, nextPos.y);
    }
    
    
    public void select(int mouseX, int mouseY) {
        selected = dist(pos.x, pos.y, mouseX, mouseY) < 2;
    }
    
    
    public String toString() {
        return id + ": " + pos + " [" + lanes.size() + "]"; 
    }
    
}