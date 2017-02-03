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
                
                if( location.x > 0 && location.x < width && location.y > 0 && location.y < height ) {
                    pois.add( new POI(roads, count, location, name, capacity) );
                    counter.increment(clusterName);
                    count++;
                }
                
            }
        }
        
        return pois;
    }
      
     
    public ArrayList<POI> loadFromCSV(String path, Roads roads) {
         
        ArrayList<POI> pois = new ArrayList();
        int count = count();
        
        Table table = loadTable(path, "header, tsv");
        for(TableRow row : table.rows()) {
            
            String name         = row.getString("NAME");
            PVector location    = roads.toXY(row.getFloat("LAT"), row.getFloat("LNG"));
            int capacity        = row.getInt("CAPACITY");
            int size            = 3;
            
            if( location.x > 0 && location.x < width && location.y > 0 && location.y < height ) {
                pois.add( new POI(roads, count, location, name, capacity) );
                counter.increment(path); 
                count++;
            }
        }
            
        return pois;
    }
     
}



// POI CLASSES -------------->
public class POI implements Placeable {

    private final int ID;
    private final String NAME;
    private final PVector POSITION;
    private final Node NODE;
    private final int CAPACITY;
    
    private int occupancy;
    private boolean selected;
    
    
    public POI(Roads roadmap, int id, PVector position, String name, int capacity) {
        ID = id;
        NAME = name;
        CAPACITY = capacity;
        NODE = roadmap.connect(position);
        POSITION = position;
    }
    
    
    public PVector getPosition() {
        return POSITION;
    }
    
    public Node getNode() {
        return NODE;
    }
    
    
    public void draw() {
        
        float normalizedOccupancy = (float)occupancy / CAPACITY;
        color c = lerpColor(#FFFF00, #FF0000, normalizedOccupancy);
        float size = (1 + 10 * normalizedOccupancy);
        
        stroke(c, 100); strokeWeight(2); noFill(); rectMode(CENTER);
        rect(getPosition().x, getPosition().y, size, size);
        point(POSITION.x, POSITION.y);
        
        if( selected ) {
            fill(0); textAlign(CENTER, BOTTOM);
            text(NAME, POSITION.x, POSITION.y);
        }

    }

    public void select(int mouseX, int mouseY) {
        selected = dist(POSITION.x, POSITION.y, mouseX, mouseY) < 5;
    }
    

}