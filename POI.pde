// POI FACADE -------------->
public class PointsOfInterest extends Facade {

    public PointsOfInterest(PApplet papplet, Roads roadmap) {
        super(papplet, roadmap);
        fabric = new POIFabric();
    }
    
}


// POI FABRIC -------------->
private class POIFabric extends Fabric {
    
    public ArrayList<POI> loadFromJSON(File JSONFile, Roads roads) {
        
        ArrayList<POI> pois = new ArrayList();
        int count = count();
        
        JSONArray clusters = loadJSONArray(JSONFile);
        for(int i = 0; i < clusters.size(); i++) {
            JSONObject cluster = clusters.getJSONObject(i);
            
            String type        = cluster.getString("type");
            String clusterName = cluster.getString("name");
            JSONObject style   = cluster.getJSONObject("style");
            String tint        = style.getString("color");
            int size           = style.getInt("size");
            
            JSONArray items   = cluster.getJSONArray("items");
            for(int j = 0; j < items.size(); j++) {
                JSONObject item = items.getJSONObject(j);
                
                int id              = item.getInt("id");
                String name         = item.getString("name");
                PVector location    = roads.toXY(
                                        item.getJSONArray("location").getFloat(0),
                                        item.getJSONArray("location").getFloat(1)
                                    );
                int capacity        = item.getInt("capacity");
                JSONArray languages = item.getJSONArray("languages");
                
                pois.add( new POI(roads, count, location, name, capacity, size) );
                counter.increment(clusterName);
                count++;
                
            }
        }
        
        return pois;
    }
      
     
    public ArrayList<POI> loadFromCSV(String pathTSV, Roads roads) {
         
        ArrayList<POI> pois = new ArrayList();
        int count = count();
        
        Table table = loadTable(pathTSV, "header, tsv");
        for(TableRow row : table.rows()) {
            
            String name         = row.getString("NAME");
            PVector location    = roads.toXY(row.getFloat("LAT"), row.getFloat("LNG"));
            int capacity        = row.getInt("CAPACITY");
            int size            = 3;
            
            pois.add( new POI(roads, count, location, name, capacity, size) );
            counter.increment(pathTSV); 
            count++;
        }
            
        return pois;
    }
     
}



// POI CLASSES -------------->
public class POI implements Placeable {

    private final int ID;
    private final String NAME;
    private final int CAPACITY;
    private final int MIN_SIZE;
    
    private final Node NODE;
    private PVector conn;
    private final PVector POS;
    
    private int occupancy;
    private boolean selected;
    
    
    public POI(Roads roadmap, int id, PVector pos, String name, int capacity, int minSize) {
        ID = id;
        NAME = name;
        CAPACITY = capacity;
        MIN_SIZE = minSize;
        
        occupancy = round( random(0, CAPACITY) );
        
        POS = pos;
        
        NODE = null;
        
        // Connect poi to roadmap
        //NODE = connect(roadmap, pos);
        //conn = connect(roadmap, pos);
        
    }
    
    
    public PVector getPosition() {
        return POS.copy();
    }
    
    
    public void draw() {
        float occup = (float)occupancy / CAPACITY;
        color c = lerpColor(#FFFF00, #FF0000, occup);
        float size = (1 + 10 * occup) * MIN_SIZE;
        
        fill(c, 100); noStroke();
        ellipse(POS.x, POS.y, size, size);
        fill(c);
        ellipse(POS.x, POS.y, MIN_SIZE, MIN_SIZE);
        
        if( selected ) {
            fill(0); textAlign(CENTER, BOTTOM);
            text(NAME, POS.x, POS.y);
        }
        
        //connPos = connectNode.getPosition();
        //stroke(#FF0000);
        //line(POS.x, POS.y, conn.x, conn.y);
    }
    
    
    /*
    private Node connect(Roads roadmap, PVector pos) {
        Lane closeLane = roadmap.closestLane(pos);
        Lane closeLaneBack = closeLane.getNode().laneTo( closeLane.getParentNode() );
        PVector connectPoint = roadmap.closestPoint(closeLane, pos);
        
        // Check first node
        Node connectNode = null;
        if(connectPoint == closeLane.getNode().getPosition()) connectNode = closeLane.getNode();
        else {
            if(connectPoint == closeLane.getParentNode().getPosition()) connectNode = closeLane.getParentNode();
            else {
                connectNode = closeLane.split(connectPoint);
                closeLaneBack.split(connectNode);
            }
        }
        
        Node node = new Node(pos);
        connectNode.connectBoth(node, null, "POI access");
        
        if(connectNode.getID() == -1) {
            connectNode.setID( roadmap.size() );
            roadmap.add(connectNode);
        }
        
        return node;
    }
    */
    
    public void select(int mouseX, int mouseY) {
        selected = dist(POS.x, POS.y, mouseX, mouseY) < MIN_SIZE;
    }
    

}