private class Lane {
    
    private String name;
    
    private Node initNode;
    private Node finalNode;
    private float distance;
    private ArrayList<PVector> vertices;
    private boolean open = true;
    
    private int maxCrowd = 10;
    private ArrayList<Agent> crowd = new ArrayList();
    
    
    public Lane(String _name, Node _initNode, Node _finalNode, ArrayList<PVector> _vertices) {
        name = _name;
        initNode = _initNode;
        finalNode = _finalNode;
        if(_vertices != null && _vertices.size() != 0) vertices = new ArrayList(_vertices);
        else {
            vertices = new ArrayList();
            vertices.add(initNode.getPosition());
            vertices.add(finalNode.getPosition());
        }
        distance = computeLength();
    }
    
    
    public Node getFinalNode() { return finalNode; }
    public ArrayList<PVector> getVertices() { return new ArrayList(vertices); }
    public PVector getVertex(int i) {
        if(i >= 0  && i < vertices.size()) return vertices.get(i).copy();
        return null;
    }
    
    public float computeLength() {
        float dist = 0;
        for(int i = 1; i < vertices.size(); i++) dist += vertices.get(i-1).dist( vertices.get(i) );
        return dist;
    }
    
    public float getLength() { return distance; }
    
    public boolean isOpen() { return open; }
   
    public int size() { return vertices.size(); }
    
    public boolean contains(PVector vertex) {
        return vertices.indexOf(vertex) >= 0;
    }


    public PVector nextVertex(PVector vertex) {
        int i = vertices.indexOf(vertex) + 1;
        if(i > 0 && i < vertices.size()) return vertices.get(i);
        return null;
    }

    public boolean isLastVertex( PVector vertex ) {
        return vertex.equals( vertices.get( vertices.size() - 1 ) );
    }
    
    
    public Lane findContrariwise() {
        for(Lane otherLane : finalNode.outboundLanes()) {
            if( otherLane.isContrariwise(this) ) return otherLane;
        }
        return null;
    }
    
    
    public boolean isContrariwise(Lane lane) {
        ArrayList<PVector> reversedVertices = new ArrayList(lane.getVertices());
        Collections.reverse(reversedVertices);
        return vertices.equals(reversedVertices);
    }
    
    
    public PVector findClosestPoint(PVector position) {
        Float minDistance = Float.NaN;
        PVector closestPoint = null;
        for(int i = 1; i < vertices.size(); i++) {
            PVector projectedPoint = Geometry.scalarProjection(position, vertices.get(i-1), vertices.get(i));
            float distance = PVector.dist(position, projectedPoint);
            if(minDistance.isNaN() || distance < minDistance) {
                minDistance = distance;
                closestPoint = projectedPoint;
            }
        }
        return closestPoint;
    }
    
    protected boolean divide(Node node) {
        int i = vertices.indexOf(node.getPosition());
        if(i > 0 && i < vertices.size()-1) {
            ArrayList<PVector> dividedVertices = new ArrayList( vertices.subList(i, vertices.size()) );
            node.connect(finalNode, dividedVertices, name);
            vertices = new ArrayList( vertices.subList(0, i+1) );
            finalNode = node;
            distance = computeLength();
            return true;
        }
        return false;
    }
    
    
    protected Node split(Node node) {
        for(int i = 1; i < vertices.size(); i++) {
            if( Geometry.inLine(node.getPosition(), vertices.get(i-1), vertices.get(i)) ) {
                
                ArrayList<PVector> splittedVertices = new ArrayList();
                splittedVertices.add(node.getPosition());
                splittedVertices.addAll( vertices.subList(i, vertices.size()) );
                node.connect(finalNode, splittedVertices, name);
                
                vertices = new ArrayList( vertices.subList(0, i) );
                vertices.add(node.getPosition());
                finalNode = node;
                distance = computeLength();
            }
        }
        return null;
    }
    
    
    public void draw(int stroke, color c) {
        float crowdN = (float) crowd.size() / maxCrowd;
        color a = lerpColor(c, #FF0000, crowdN);
        for(int i = 1; i < vertices.size(); i++) {
            stroke(a, 127); strokeWeight(stroke);
            PVector prevVertex = vertices.get(i-1);
            PVector vertex = vertices.get(i);
            line(prevVertex.x, prevVertex.y, vertex.x, vertex.y); 
        }
    }
    
    
    public void addAgent(Agent agent) {
        crowd.add(agent);
    }
    
    
    public void removeAgent(Agent agent) {
        crowd.remove(agent);
    }
    
    
    @Override
    public String toString() {
        return name + " with " + vertices.size() + "vertices [" + vertices + "]";
    }
    
}