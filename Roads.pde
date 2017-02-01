import java.util.Collections;
import java.util.*;

public class Roads {

    private ArrayList<Node> nodes = new ArrayList();
    private PVector[] boundaries;
    
    
    public Roads(String file) {
        
        boundaries = findBounds(file);
        
        JSONObject roadNetwork = loadJSONObject(file);
        JSONArray lanes = roadNetwork.getJSONArray("features");
        for(int i = 0; i < lanes.size(); i++) {
            JSONObject lane = lanes.getJSONObject(i);
            
            JSONObject props = lane.getJSONObject("properties");
            String type = props.isNull("type") ? "null" : props.getString("type");
            String name = props.isNull("name") ? "null" : props.getString("name");
            //boolean oneWay = props.isNull("oneway") ? false : props.getBoolean("oneway");
      
            JSONArray points = lane.getJSONObject("geometry").getJSONArray("coordinates");
            
            Node prevNode = null;
            ArrayList vertices = new ArrayList();
            for(int j = 0; j < points.size(); j++) {
            
                PVector point = toXY(points.getJSONArray(j).getFloat(1), points.getJSONArray(j).getFloat(0));
                
                Node node = null;
                for(Node n : nodes) {
                    node = n.find( new Node(point) );
                    if(node != null) {
                        if(prevNode != null) {
                            prevNode.connectBoth(node, vertices, name);
                            vertices = new ArrayList();
                        }
                        prevNode = node;
                        break;
                    }
                }
                
                // Point is new
                if(node == null) {
                    if(j == 0 || j == points.size() - 1) { // Is first or last point is a node
                        node = new Node(point);
                        if(prevNode != null) prevNode.connectBoth(node, vertices, name);
                        prevNode = node;
                    } else vertices.add(point);
                }
                
                // Save node if NEW (not registered)
                if( node != null && node.getID() == -1 ) {
                    node.setID( nodes.size() );
                    nodes.add(node);
                }
                
            }
        }
    }



    public ArrayList<Node> getNodes() {
        return nodes;
    }
    
    public Node getFinalNode(int i) {
        return nodes.get(i);
    }
    
    public Node randomNode() {
        return nodes.get( (int) random(0, nodes.size()-1 ) );
    }
    

    private PVector[] findBounds(String file) {
        
        float minLat = Float.MAX_VALUE;
        float maxLat = Float.MIN_VALUE;
        float minLng = Float.MAX_VALUE;
        float maxLng = Float.MIN_VALUE;
        
        JSONObject roadNetwork = loadJSONObject(file);
        JSONArray lanes = roadNetwork.getJSONArray("features");
        for(int i = 0; i < lanes.size(); i++) {
            JSONObject lane = lanes.getJSONObject(i);
            JSONArray points = lane.getJSONObject("geometry").getJSONArray("coordinates");
            for(int j = 0; j < points.size(); j++) {
                float lat = points.getJSONArray(j).getFloat(1);
                float lng = points.getJSONArray(j).getFloat(0);
                minLat = min( minLat, lat );
                maxLat = max( maxLat, lat );
                minLng = min( minLng, lng );
                maxLng = max( maxLng, lng );
            }
        }
        
        return new PVector[] {
            Projection.toUTM(minLat, minLng, Projection.Datum.WGS84),
            Projection.toUTM(maxLat, maxLng, Projection.Datum.WGS84)
        };
        
    }

    
    public PVector toXY(float lat, float lng) {
        PVector projPoint = Projection.toUTM(lat, lng, Projection.Datum.WGS84);
        return new PVector(
            map(projPoint.x, boundaries[0].x, boundaries[1].x, 0, width),
            map(projPoint.y, boundaries[0].y, boundaries[1].y, height, 0)
        );
    }
    
    
    public float toMeters(float px) {
        return px * (boundaries[1].x - boundaries[0].x) / width;
    }
    
    
    public void draw(int stroke, color c) {
        for(Node node : nodes) node.draw(stroke, c);
    }
    
    
    public PVector closestPoint(PVector pos) {
        Lane closestLane = closestLane(pos);
        return closestPoint(closestLane, pos);
    }
    
    
    public PVector closestPoint(Lane lane, PVector pos) {
        float minDist = Float.MAX_VALUE;
        PVector closest = null;
        for(int i = 1; i < lane.size(); i++) {
            PVector projPoint = Geometry.scalarProjection(pos, lane.getVertices().get(i-1), lane.getVertices().get(i));
            float dist = PVector.dist(pos, projPoint);
            if(dist < minDist) {
                minDist = dist;
                closest = projPoint;
            }
        }
        return closest;
    }
    
    
    public Lane closestLane(PVector pos) {
        float minDist = Float.MAX_VALUE;
        Lane closest = null;
        for(Node node : nodes) {
            for(Lane lane : node.outboundLanes()) {
                float dist = PVector.dist(pos, closestPoint(lane, pos));
                if(dist < minDist) {
                    minDist = dist;
                    closest = lane;
                }
            }
        }
        return closest;
    }
    
    
    public Node closestNode(PVector pos) {
        float minDist = Float.MAX_VALUE;
        Node closest = null;
        for(Node node : nodes) {
            float dist = PVector.dist(pos, node.getPosition());
            if(dist < minDist) {
                minDist = dist;
                closest = node;
            }
        }
        return closest;
    }
    
}




private class Node implements Placeable {

    private int id;
    protected PVector pos;
    private ArrayList<Lane> lanes = new ArrayList();
    
    // Pathfinding variables
    private Node parent;
    private float f;
    private float g;
    private float h;
    
    public Node(PVector pos) {
        this.id = -1;
        this.pos = pos;
    }
    
    
    public void setID(int id) {
        this.id = id;
    }
    
    public int getID() {
        return id;
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
    public void setParent(Node parent) { this.parent = parent; }
    public Node getParent() { return parent; }
    public void setG(float cost) { g = cost; }
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
    
    
    protected Node find(Node node) {
        if( pos.equals(node.getPosition()) ) return this;
        for(Lane lane : outboundLanes()) {
            if( lane.getFinalNode().getPosition().equals(node.getPosition()) ) return lane.getFinalNode();
            else {
                Lane laneBack = lane.getFinalNode().shortestLaneTo(this);
                Node newNode = lane.split(node);
                if(newNode != null) {
                    if(laneBack != null) newNode = laneBack.split(newNode);
                    //Lane laneBack = last.shortestLaneTo(this);
                    //if(laneBack != null) newNode = laneBack.split(newNode);
                    return newNode;
                }
            }
        }
        return null;
    }
    
    public void draw() {
        stroke(#000000);
        point(pos.x, pos.y);
    }
    
    public void draw(int stroke, color c) {
        fill(c); noStroke();
        for(Lane lane : lanes) {
            lane.draw(stroke, c);
        }
    }
    
    public void draw(Node n, int stroke, color c) {
        Lane edge = shortestLaneTo(n);
        edge.draw(stroke, c);
        PVector nextPos = edge.getFinalNode().getPosition();
        textAlign(LEFT, CENTER); textSize(9); fill(#990000);
        text(edge.getLength(), nextPos.x + 5, nextPos.y);
    }
    
    
    public void select(int mousX, int mouseY) {}
    
    
    public String toString() {
        return id + ": " + pos + " [" + lanes.size() + "]"; 
    }
    
}


private class Lane implements Comparable<Lane> {
    
    private String name;
    
    private Node initNode;
    private Node finalNode;
    private float length;
    private ArrayList<PVector> vertices = new ArrayList();
    private boolean open = true;
    
    private ArrayList<Agent> crowd = new ArrayList();
    
    
    public Lane(String name, Node initNode, Node finalNode, ArrayList<PVector> vertices) {
        this.name = name;
        this.initNode = initNode;
        this.finalNode = finalNode;
        this.vertices.add(initNode.getPosition());
        if(vertices != null) this.vertices.addAll(vertices);
        this.vertices.add(finalNode.getPosition());
        computeLength();

    }
    
    
    public Node getInitNode() { return initNode; }
    public Node getFinalNode() { return finalNode; }
    public ArrayList<PVector> getVertices() { return new ArrayList(vertices); }
    public PVector getVertex(int i) {
        if(i >= 0  && i < vertices.size()) return vertices.get(i).copy();
        return null;
    }
    
    public void computeLength() {
        length = 0;
        for(int i = 1; i < vertices.size(); i++) {
            length += vertices.get(i-1).dist( vertices.get(i) );
        }
    }
    public float getLength() { return length; }
    
    public boolean isOpen() { return open; }
   
    public int size() { return vertices.size(); }
    
    public boolean contains(PVector vertex) {
        return vertices.indexOf(vertex) >= 0;
    }
   
    public PVector getLastVertex() {
        return vertices.get( vertices.size() - 1 );
    }
    
    public boolean isLastVertex( PVector vertex ) {
        return vertex.equals( getLastVertex() );
    }
    
    /*
    protected Node split(PVector pos) {
        int index = vertices.indexOf(pos);
        if(index > 0 && index < vertices.size()-1) {
            Node newNode = new Node(pos);
            ArrayList<PVector> splittedVertices = new ArrayList( vertices.subList(index, vertices.size()) );
            newNode.connect(finalNode, splittedVertices, name);
            finalNode = newNode;
            vertices = new ArrayList( vertices.subList(0, index) );
            computeLength();
            return newNode;
        }
        return null;
    }
    */
    
    protected Node split(Node node) {
        for(int i = 0; i < vertices.size(); i++) {
            if( vertices.get(i).equals(node.getPosition()) ) {
                
                ArrayList<PVector> splittedVertices = i >= vertices.size()-2 ? new ArrayList() : new ArrayList(vertices.subList(i + 1, vertices.size()-1));
                node.connect(finalNode, splittedVertices, name);
                vertices = new ArrayList( vertices.subList(0, i + 1) );
                
                length = 0;
                for(int j = 1; j < this.vertices.size(); j++) {
                    length += this.vertices.get(i-1).dist( this.vertices.get(i) );
                }
                
                finalNode = node;
                return node;
            }
        }
        return null;
    }

    /*
    protected Node break(PVector point) {
        for(int i = 0; i < vertices.size() - 1; i++) {
            if( Geometry.inLine(point, vertices.get(i), vertices.get(i+1)) ) {
                Node newNode = new Node(point);
                newNode.connect(finalNode, new ArrayList( vertices. ));
            }
        }
        return null;
    }
    */
    
    public void draw(int stroke, color c) {
        stroke(c); strokeWeight(stroke);
        for(int i = 1; i < vertices.size(); i++) {
            PVector vertex = vertices.get(i);
            PVector prevVertex = vertices.get(i-1);
            line(prevVertex.x, prevVertex.y, vertex.x, vertex.y);
        }
    }
    
    
    @Override
    public int compareTo(Lane s) {
        if(getLength() < s.getLength()) return - 1;
        else if(getLength() > s.getLength()) return 1;
        else return 0;
    }
    
}


static final Comparator<Lane> LENGTH = new Comparator<Lane>() {
    public int compare(Lane s1, Lane s2) {
        if(s1.getLength() < s2.getLength()) return - 1;
        else if(s1.getLength() > s2.getLength()) return 1;
        else return 0;
    }
};




public static class Geometry {
    
    public static boolean inLine(PVector p, PVector l1, PVector l2) {
        final float EPSILON = 0.001f;
        PVector l1p = PVector.sub(p, l1);
        PVector line = PVector.sub(l2, l1);
        return PVector.angleBetween(l1p, line) <= EPSILON && l1p.mag() < line.mag();
    }
    
    public static PVector scalarProjection(PVector p, PVector a, PVector b) {
        PVector ap = PVector.sub(p, a);
        PVector ab = PVector.sub(b, a);
        float abLength = ab.mag();
        ab.normalize();
        float dotProd = ap.dot(ab);
        ab.mult( dotProd );
        return ab.mag() > abLength ? b : dotProd < 0 ? a : PVector.add(a, ab);
    }
}