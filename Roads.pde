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
            boolean oneWay = props.isNull("oneway") ? false : props.getInt("oneway") == 1 ? true : false;
            //boolean oneWay = false;
      
            JSONArray points = lane.getJSONObject("geometry").getJSONArray("coordinates");
            
            Node prevNode = null;
            Node currNode = null;
            ArrayList vertices = new ArrayList();
            
            for(int j = 0; j < points.size(); j++) {
            
                PVector point = toXY(points.getJSONArray(j).getFloat(1), points.getJSONArray(j).getFloat(0));
                
                vertices.add(point);
                
                currNode = createNodeIfVertex(point);
                if(currNode != null) {
                    if(j > 0 && j < points.size()) {
                        
                        if(oneWay) prevNode.connect(currNode, vertices, name);
                        else prevNode.connectBoth(currNode, vertices, name);
                        
                        vertices = new ArrayList();
                        vertices.add(point);
                        prevNode = currNode;
                    }
                } else currNode = new Node(point);
                
                
                if(j == 0) {
                    prevNode = currNode;
                    currNode.register(nodes);
                } else if(j == points.size()-1) {
                    if(oneWay) prevNode.connect(currNode, vertices, name);
                    else prevNode.connectBoth(currNode, vertices, name);
                    currNode.register(nodes);
                }
                
            }
        }
    }


    private Node createNodeIfVertex(PVector position) {
        for(Node node : nodes) {
            if( position.equals(node.getPosition()) ) return node;
            for(Lane lane : node.outboundLanes()) {
                if( position.equals(lane.getFinalNode().getPosition()) ) return lane.getFinalNode();
                else if( lane.contains(position) ) {
                    Lane laneBack = lane.findContrariwise();
                    Node newNode = new Node(position);
                    if(lane.split(newNode)) {
                        if(laneBack != null) laneBack.split(newNode);
                        newNode.register(nodes);
                        return newNode;
                    }
                }
            }
        }
        return null;
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
    
    
    public void select(int mouseX, int mouseY) {
        for(Node node : nodes) node.select(mouseX, mouseY);
    }
    
}




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
        
        if(id == 172 || id == 38 || id == 273 ||id == 274 ||id == 8 ||id == 283 ||id == 651) {
            stroke(#FF0000); strokeWeight(3);
            point(pos.x, pos.y);
        }
        
        for(Lane lane : lanes) {
            if(selected) {
                lane.draw(2, #FF0000);
                fill(0); textSize(8);
                text(id, pos.x, pos.y);
            }
            else lane.draw(stroke, c);
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
        selected = dist(pos.x, pos.y, mouseX, mouseY) < 5;
    }
    
    
    public String toString() {
        return id + ": " + pos + " [" + lanes.size() + "]"; 
    }
    
}


private class Lane implements Comparable<Lane> {
    
    private String name;
    
    private Node initNode;
    private Node finalNode;
    private float length;
    private ArrayList<PVector> vertices;
    private boolean open = true;
    
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
        length = computeLength();
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
    
    public float getLength() { return length; }
    
    public boolean isOpen() { return open; }
   
    public int size() { return vertices.size(); }
    
    public boolean contains(PVector vertex) {
        return vertices.indexOf(vertex) >= 0;
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
    
    
    protected boolean split(Node node) {
        int i = vertices.indexOf(node.getPosition());
        if(i > 0 && i < vertices.size()-1) {
            ArrayList<PVector> splittedVertices = new ArrayList( vertices.subList(i, vertices.size()) );
            node.connect(finalNode, splittedVertices, name);
            vertices = new ArrayList( vertices.subList(0, i+1) );
            finalNode = node;
            length = computeLength();
            return true;
        }
        return false;
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
            PVector prevVertex = vertices.get(i-1);
            PVector vertex = vertices.get(i);
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


/*
static final Comparator<Lane> LENGTH = new Comparator<Lane>() {
    public int compare(Lane s1, Lane s2) {
        if(s1.getLength() < s2.getLength()) return - 1;
        else if(s1.getLength() > s2.getLength()) return 1;
        else return 0;
    }
};
*/



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