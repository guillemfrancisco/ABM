import java.util.Collections;
import java.util.*;

public class Roads {

    private ArrayList<Node> nodes = new ArrayList();
    private PVector[] boundaries;
    
    
    public Roads(String file) {
        
        boundaries = findBounds(file);
        
        JSONObject roadNetwork = loadJSONObject(file);
        JSONArray streets = roadNetwork.getJSONArray("features");
        for(int i = 0; i < streets.size(); i++) {
            JSONObject street = streets.getJSONObject(i);
            
            JSONObject props = street.getJSONObject("properties");
            String type = props.isNull("type") ? "null" : props.getString("type");
            String name = props.isNull("name") ? "null" : props.getString("name");
            //boolean oneWay = props.isNull("oneway") ? false : props.getBoolean("oneway");
      
            JSONArray points = street.getJSONObject("geometry").getJSONArray("coordinates");
            
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
    
    public Node getNode(int i) {
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
        JSONArray streets = roadNetwork.getJSONArray("features");
        for(int i = 0; i < streets.size(); i++) {
            JSONObject street = streets.getJSONObject(i);
            JSONArray points = street.getJSONObject("geometry").getJSONArray("coordinates");
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
        PVector projected = Projection.toUTM(lat, lng, Projection.Datum.WGS84);
        return new PVector(
            map(projected.x, boundaries[0].x, boundaries[1].x, 0, width),
            map(projected.y, boundaries[0].y, boundaries[1].y, height, 0)
        );
    }
    
    
    public float toMeters(float px) {
        return px * (boundaries[1].x - boundaries[0].x) / width;
    }
    
    
    public void draw(int stroke, color c) {
        for(Node node : nodes) node.draw(stroke, c);
    }
    
    
    public PVector closestPoint(PVector pos) {
        Street closestStreet = closestStreet(pos);
        return closestPoint(closestStreet, pos);
    }
    
    
    public PVector closestPoint(Street street, PVector pos) {
        float minDist = Float.MAX_VALUE;
        PVector closest = null;
        ArrayList<PVector> vertices = street.getVertices();
        for(int i = 1; i < vertices.size(); i++) {
            PVector projPoint = Geometry.scalarProjection(pos, vertices.get(i-1), vertices.get(i));
            float dist = PVector.dist(pos, projPoint);
            if(dist < minDist) {
                minDist = dist;
                closest = projPoint;
            }
        }
        return closest;
    }
    
    
    public Street closestStreet(PVector pos) {
        float minDist = Float.MAX_VALUE;
        Street closest = null;
        for(Node node : nodes) {
            for(Street street : node.outboundStreets()) {
                float dist = PVector.dist(pos, closestPoint(street, pos));
                if(dist < minDist) {
                    minDist = dist;
                    closest = street;
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
    private ArrayList<Street> streets = new ArrayList();
    
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
    
    public ArrayList<Street> outboundStreets() {
        return streets;
    }
    
    public Street streetTo(Node node) {
        /*  GIVES ERROR
        ArrayList<Street> streetsToNode = new ArrayList();
        for(Street street : outboundStreets()) {
            if(street.getNode().equals(node)) streetsToNode.add(street);
        }
        Collections.sort(streetsToNode, LENGTH);
        println("");
        return streetsToNode.size() == 0 ? null : streetsToNode.get(0);
        */
        
        float minDist = Float.MAX_VALUE;
        Street shortest = null;
        for(Street street : outboundStreets()) {
            if( node.equals(street.getNode() ) && street.getLength() < minDist) {
                minDist = street.getLength();
                shortest = street;
            }
        }
        return shortest;
        
    }
    
    public ArrayList<Node> getNeighbors() {
        ArrayList<Node> neighbors = new ArrayList();
        for(Street street : outboundStreets()) neighbors.add( street.getNode() );
        return neighbors;
    }
    
    
    public void disconnect(Node node) {
        for(Street street : outboundStreets()) {
            if( node.equals(street.getNode()) ) outboundStreets().remove(street);
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
        streets.add( new Street(name, this, node, vertices) );
    }
    
    
    protected void connectBoth(Node node, ArrayList<PVector> vertices, String name) {
        connect(node, vertices, name);
        if(vertices != null) Collections.reverse(vertices);
        node.connect(this, vertices, name);
    }
    
    
    protected Node find(Node node) {
        if( pos.equals(node.getPosition()) ) return this;
        for(Street street : outboundStreets()) {
            if( street.getNode().getPosition().equals(node.getPosition()) ) return street.getNode();
            else {
                Street streetBack = street.getNode().streetTo(this);
                Node newNode = street.split(node);
                if(newNode != null) {
                    if(streetBack != null) newNode = streetBack.split(newNode);
                    //Street streetBack = last.streetTo(this);
                    //if(streetBack != null) newNode = streetBack.split(newNode);
                    return newNode;
                }
            }
        }
        return null;
    }
    
    
    public void draw(int stroke, color c) {
        fill(c); noStroke();
        for(Street street : streets) {
            street.draw(stroke, c);
        }
    }
    
    
    public void draw(Node n, int stroke, color c) {
        Street edge = streetTo(n);
        edge.draw(stroke, c);
        PVector nextPos = edge.getNode().getPosition();
        textAlign(LEFT, CENTER); textSize(9); fill(#990000);
        text(edge.getLength(), nextPos.x + 5, nextPos.y);
    }
    
    public String toString() {
        return id + ": " + pos + " [" + streets.size() + "]"; 
    }
    
}


private class Street implements Comparable<Street> {
    
    private String name;
    
    private Node fromNode;
    private Node toNode;
    private float length = 0;
    private ArrayList<PVector> vertices = new ArrayList();
    private boolean open = true;
    
    private ArrayList<Agent> crowd = new ArrayList();
    
    
    public Street(String name, Node fromNode, Node toNode, ArrayList<PVector> vertices) {
        this.name = name;
        this.fromNode = fromNode;
        this.toNode = toNode;
        this.vertices.add(fromNode.getPosition());
        if(vertices != null) this.vertices.addAll(vertices);
        this.vertices.add(toNode.getPosition());
        for(int i = 1; i < this.vertices.size(); i++) {
            length += this.vertices.get(i-1).dist( this.vertices.get(i) );
        }

    }
    
    
    public Node getParentNode() { return fromNode; }
    public Node getNode() { return toNode; }
    public ArrayList<PVector> getVertices() { return new ArrayList(vertices); }
    public PVector getVertex(int i) {
        if(i >= 0  && i < vertices.size()) return vertices.get(i).copy();
        return null;
    }
    public float getLength() { return length; }
    public boolean isOpen() { return open; }
   
    
    public int size() { return vertices.size(); }
    public boolean contains(PVector vertex) {
        return vertices.indexOf(vertex) >= 0;
    }
   
    
    public PVector getLast() {
        return vertices.get( vertices.size() - 1 );
    }
    
    public boolean isLast( PVector vertex ) {
        return vertex.equals( getLast() );
    }
    
    protected Node split(Node node) {
        for(int i = 0; i < vertices.size(); i++) {
            if( vertices.get(i).equals(node.getPosition()) ) {
                
                ArrayList<PVector> splittedVertices = i >= vertices.size()-2 ? new ArrayList() : new ArrayList(vertices.subList(i + 1, vertices.size()-1));
                node.connect(toNode, splittedVertices, name);
                vertices = new ArrayList( vertices.subList(0, i + 1) );
                
                length = 0;
                for(int j = 1; j < this.vertices.size(); j++) {
                    length += this.vertices.get(i-1).dist( this.vertices.get(i) );
                }
                
                toNode = node;
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
                newNode.connect(toNode, new ArrayList( vertices. ));
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
    public int compareTo(Street s) {
        if(getLength() < s.getLength()) return - 1;
        else if(getLength() > s.getLength()) return 1;
        else return 0;
    }
    
}


static final Comparator<Street> LENGTH = new Comparator<Street>() {
    public int compare(Street s1, Street s2) {
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