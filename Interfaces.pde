public interface Placeable {
    public void place(Roads roads);
    public PVector getPosition();
    public void select(int mouseX, int mouseY);
    public void draw();
}


public interface Predicate<T> {
    public boolean evaluate(T type);
}