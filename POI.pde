public class POI extends Node {

    private String name;
    private int capacity;
    
    private PVector connectionPoint;
    
    public POI(PVector pos, String name, int capacity) {
        super(pos);
        this.name = name;
        this.capacity = capacity;
    }
    
    @Override
    public void draw(int stroke, color c) {
        fill(#009900); rectMode(CENTER);
        rect(pos.x, pos.y, 5, 5);
        //line(pos.x, pos.y, connectionPoint.x, connectionPoint.y);
    }

}