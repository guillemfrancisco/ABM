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



public static class Filters {

    public static Predicate<Agent> closeToPoint(final PVector point) {
        return new Predicate<Agent>() {
            public boolean evaluate(Agent item) {
                return point.dist(item.getPosition()) < 100;
            }
        };
    }
    
    public static Predicate<Agent> isMoving(final boolean moving) {
        return new Predicate<Agent>() {
            public boolean evaluate(Agent agent) {
                return agent.isMoving() == moving;
            }
        };
    }
    
    
}