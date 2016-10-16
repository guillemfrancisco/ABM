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
                    
                    pois.add( new POI(roads, pois.size(), location, name, capacity, size) );
                    counter.increment(clusterName);
                    
                }
                
            }
            
            return pois;
     }
      
     
     public ArrayList<POI> loadFromCSV(String pathTSV, Roads roads) {
        ArrayList<POI> pois = new ArrayList();
        
        Table table = loadTable(pathTSV, "header, tsv");
        for(TableRow row : table.rows()) {
            
            String name         = row.getString("NAME");
            PVector location    = roads.toXY(row.getFloat("LAT"), row.getFloat("LNG"));
            int capacity        = row.getInt("CAPACITY");
            int size            = 3;
            
            pois.add( new POI(roads, pois.size(), location, name, capacity, size) );
            counter.increment(pathTSV); 
        }
            
        return pois;
     }
     
}



// POI CLASSES -------------->
public class POI implements MapItem, Placeable {

    private final int ID;
    private final String NAME;
    private final int CAPACITY;
    private final int MIN_SIZE;
    
    private final Node node;
    private final PVector POS;
    
    private int occupancy;
    private boolean selected;
    
    
    public POI(Roads roadmap, int id, PVector pos, String name, int capacity, int minSize) {
        ID = id;
        NAME = name;
        CAPACITY = capacity;
        MIN_SIZE = minSize;
        
        occupancy = round( random(0, CAPACITY) );
        
        node = null;
        POS = pos;
        
        // Connect poi to roadmap
        //node = connect(roadmap, pos);
        
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
        //line(pos.x, pos.y, connPos.x, connPos.y);
    }
    
    
    private Node connect(Roads roadmap, PVector pos) {
        Street closeStreet = roadmap.closestStreet(pos);
        PVector connectPoint = roadmap.closestPoint(closeStreet, pos);
        
        // Check first node
        Node connectNode = null;
        if(connectPoint == closeStreet.getNode().getPosition()) connectNode = closeStreet.getNode();
        else {
            if(connectPoint == closeStreet.getParentNode().getPosition()) connectNode = closeStreet.getParentNode();
            else {
                connectNode = new Node( connectPoint );
                // Connect to neighbor nodes (disconnecting between them)

            }
        }
        
        connectNode.connectBoth(node, null, "POI access");
        
        /*
        if(connectNode.getID() == -1) {
            connectNode.setID( nodes.size() );
            nodes.add(poi);
        }
        */
        
        return null;
    }
    
    
    public void select(int mouseX, int mouseY) {
        selected = dist(POS.x, POS.y, mouseX, mouseY) < MIN_SIZE;
    }
    

}