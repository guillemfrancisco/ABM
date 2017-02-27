import java.util.Collections;
import java.util.*;

/**
* Roads - Class to manage the roadmap of simulation
* @author        Marc Vilella
* @version       2.0
*/
public class Roads {

    private ArrayList<Node> nodes = new ArrayList();
    private PVector[] boundaries;
   
    
    /**
    * Initiate roadmap from a GeoJSON file
    * @param file  GeoJSON file containing roads description. Use OpenStreetMap (OSM) format
    */
    public Roads(String file) {
        
        boundaries = findBounds(file);
        
        print("Loading roads network... ");
        JSONObject roadNetwork = loadJSONObject(file);
        JSONArray lanes = roadNetwork.getJSONArray("features");
        for(int i = 0; i < lanes.size(); i++) {
            JSONObject lane = lanes.getJSONObject(i);
            
            JSONObject props = lane.getJSONObject("properties");
            String type = props.isNull("type") ? "null" : props.getString("type");
            String name = props.isNull("name") ? "null" : props.getString("name");
            boolean oneWay = props.isNull("oneway") ? false : props.getInt("oneway") == 1 ? true : false;
      
            JSONArray points = lane.getJSONObject("geometry").getJSONArray("coordinates");
            
            Node prevNode = null;
            ArrayList vertices = new ArrayList();
            for(int j = 0; j < points.size(); j++) {
            
                PVector point = toXY(points.getJSONArray(j).getFloat(1), points.getJSONArray(j).getFloat(0));
                
                vertices.add(point);
                
                Node currNode = getNodeIfVertex(point);
                if(currNode != null) {
                    if(j > 0 && j < points.size()-1) {
                        if(oneWay) prevNode.connect(currNode, vertices, name);
                        else prevNode.connectBoth(currNode, vertices, name);
                        vertices = new ArrayList();
                        vertices.add(point);
                        prevNode = currNode;
                    }
                } else currNode = new Node(point);
                
                if(prevNode == null) {
                    prevNode = currNode;
                    currNode.place(this);
                } else if(j == points.size()-1) {
                    if(oneWay) prevNode.connect(currNode, vertices, name);
                    else prevNode.connectBoth(currNode, vertices, name);
                    currNode.place(this);
                }
                
            }
        }
        println("LOADED");
        
        /*
        Path debugPath = new Path(this, null);
        for(Node n1 : nodes) {
            for(Node n2 : nodes) {
                if(!n1.equals(n2)) {
                    if(!debugPath.findPath(n1, n2)) println("CANNOT GO FROM " + n1.id + " TO " + n2.id);
                }
            }
        }
        */
        
    }


    /**
    * Get a node if a position matches with an already existing vertex in roadmap
    * @param position  Position to compare with all vertices
    * @return a new created (not placed) node if position matches with a vertex, an already existing node if position matches with it, or
    * null if position doesn't match with any vertex
    */
    private Node getNodeIfVertex(PVector position) {
        for(Node node : nodes) {
            if( position.equals(node.getPosition()) ) return node;
            for(Lane lane : node.outboundLanes()) {
                if( position.equals(lane.getEnd().getPosition()) ) return lane.getEnd();
                else if( lane.contains(position) ) {
                    Lane laneBack = lane.findContrariwise();
                    Node newNode = new Node(position);
                    if(lane.divide(newNode)) {
                        if(laneBack != null) laneBack.divide(newNode);
                        newNode.place(this);
                        return newNode;
                    }
                }
            }
        }
        return null;
    }


    /**
    * Create a node in specified position and connects it to the roadmap through a node in the closest street point
    * @param position  Position of place to connect
    * @return new created node, already connected to roadmap
    */
    private Node connect(PVector position) {
        
        Lane closestLane = findClosestLane(position);
        Lane closestLaneBack = closestLane.findContrariwise();
        
        Node connectionNode = new Node(closestLane.findClosestPoint(position));
        closestLane.split(connectionNode);
        if(closestLaneBack != null) closestLaneBack.split(connectionNode);
        connectionNode.place(this);
            
        Node node = new Node(position);
        node.connectBoth(connectionNode, null, "Access");
        node.place(this);
        
        return node;
        
    }


    public ArrayList<Node> getAll() {
        return nodes;
    }


    public Node randomNode() {
        return nodes.get( (int) random(0, nodes.size() ) );
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
    
    
    public PVector findClosestPoint(PVector position) {
        Lane closestLane = findClosestLane(position);
        return closestLane.findClosestPoint(position);
    }

    
    public Lane findClosestLane(PVector position) {
        Float minDistance = Float.NaN;
        Lane closestLane = null;
        for(Node node : nodes) {
            for(Lane lane : node.outboundLanes()) {
                PVector linePoint = lane.findClosestPoint(position);
                float distance = position.dist(linePoint);
                if(minDistance.isNaN() || distance < minDistance) {
                    minDistance = distance;
                    closestLane = lane;
                }
            }
        }
        return closestLane;
    }

    
    public void select(int mouseX, int mouseY) {
        for(Node node : nodes) node.select(mouseX, mouseY);
    }
    
}