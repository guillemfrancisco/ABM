import java.util.Collections;
import java.util.*;

/**
* Roads - Class to manage the roadmap of simulation
* @author        Marc Vilella
* @version       2.0
*/
public class Roads extends Facade<Node> {

    private PVector window;
    private PVector[] bounds;
   
    
    /**
    * Initiate roadmap from a GeoJSON file
    * @param file  GeoJSON file containing roads description. Use OpenStreetMap (OSM) format
    */
    public Roads(String file, int x, int y, PVector[] bounds) {
        window = new PVector(x, y);
        this.bounds = bounds;
        
        factory = new RoadFactory();
        this.loadJSON(file, this);
    }


    
    private void connect(POI poi) {
        
        Lane closestLane = findClosestLane(poi.getPosition());
        Lane closestLaneBack = closestLane.findContrariwise();
        PVector closestPoint = closestLane.findClosestPoint(poi.getPosition());
        
        Node connectionNode = new Node(closestPoint);
        connectionNode = closestLane.split(connectionNode);
        if(closestLaneBack != null) connectionNode = closestLaneBack.split(connectionNode);
        this.add(connectionNode);
        
        poi.connectBoth(connectionNode, null, "Access", poi.access);
        add(poi);
        
    }

    
    @Override
    public void add(Node node) {
        if(node.getID() == -1) {
            node.setID(items.size());
            items.add(node);
        }
    }


    public PVector toXY(float lat, float lon) {
        return new PVector(
            map(lon, bounds[0].y, bounds[1].y, 0, window.x),
            map(lat, bounds[0].x, bounds[1].x, window.y, 0)
        );
    }
    
    
    public boolean contains(PVector point) {
        return point.x > 0 && point.x < window.x && point.y > 0 && point.y < window.y;
    }
    
    
    public float toMeters(float px) {
        return px * (bounds[1].x - bounds[0].x) / width;
    }
    
    
    public void draw(PGraphics canvas, int stroke, color c) {
        for(Node node : items) node.draw(canvas, stroke, c);
    }
    
    
    public PVector findClosestPoint(PVector position) {
        Lane closestLane = findClosestLane(position);
        return closestLane.findClosestPoint(position);
    }

    
    public Lane findClosestLane(PVector position) {
        Float minDistance = Float.NaN;
        Lane closestLane = null;
        for(Node node : items) {
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
        for(Node node : items) node.select(mouseX, mouseY);
    }
    
}



public class RoadFactory extends Factory {
    
    public ArrayList<Node> loadJSON(File file, Roads roads) {
        
        print("Loading roads network... ");
        JSONObject roadNetwork = loadJSONObject(file);
        JSONArray lanes = roadNetwork.getJSONArray("features");
        for(int i = 0; i < lanes.size(); i++) {
            JSONObject lane = lanes.getJSONObject(i);
            
            JSONObject props = lane.getJSONObject("properties");
            Accessible access = props.isNull("type") ? Accessible.ALL : Accessible.create( props.getString("type") );
            String name = props.isNull("name") ? "null" : props.getString("name");
            boolean oneWay = props.isNull("oneway") ? false : props.getInt("oneway") == 1 ? true : false;
            String direction = props.isNull("direction") ? null : props.getString("direction");
      
            JSONArray points = lane.getJSONObject("geometry").getJSONArray("coordinates");
            
            Node prevNode = null;
            ArrayList vertices = new ArrayList();
            for(int j = 0; j < points.size(); j++) {
            
                PVector point = roads.toXY(points.getJSONArray(j).getFloat(1), points.getJSONArray(j).getFloat(0));
                
                if( roads.contains(point) ) {
                    vertices.add(point);
                    
                    Node currNode = getNodeIfVertex(roads, point);
                    if(currNode != null) {
                        if(prevNode != null && j < points.size()-1) {
                            if(oneWay) prevNode.connect(currNode, vertices, name, access);
                            else prevNode.connectBoth(currNode, vertices, name, access);
                            vertices = new ArrayList();
                            vertices.add(point);
                            prevNode = currNode;
                        }
                    } else currNode = new Node(point);
                    
                    if(prevNode == null) {
                        prevNode = currNode;
                        currNode.place(roads);
                    } else if(j == points.size()-1) {
                        if(oneWay) prevNode.connect(currNode, vertices, name, access);
                        else prevNode.connectBoth(currNode, vertices, name, access);
                        currNode.place(roads);
                        if(direction != null) currNode.setDirection(direction);
                    }
                }
                
            }
        }
        println("LOADED");
        
        return new ArrayList();
    }
    
    
    /**
    * Get a node if a position matches with an already existing vertex in roadmap
    * @param position  Position to compare with all vertices
    * @return a new created (not placed) node if position matches with a vertex, an already existing node if position matches with it, or
    * null if position doesn't match with any vertex
    */
    private Node getNodeIfVertex(Roads roads, PVector position) {
        for(Node node : roads.getAll()) {
            if( position.equals(node.getPosition()) ) return node;
            for(Lane lane : node.outboundLanes()) {
                if( position.equals(lane.getEnd().getPosition()) ) return lane.getEnd();
                else if( lane.contains(position) ) {
                    Lane laneBack = lane.findContrariwise();
                    Node newNode = new Node(position);
                    if(lane.divide(newNode)) {
                        if(laneBack != null) laneBack.divide(newNode);
                        newNode.place(roads);
                        return newNode;
                    }
                }
            }
        }
        return null;
    }

}