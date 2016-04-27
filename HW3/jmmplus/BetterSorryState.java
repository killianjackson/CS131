import java.util.concurrent.atomic.AtomicIntegerArray;

class BetterSorryState implements State {

    // create a new Atomic Integer Array                                             
    private AtomicIntegerArray value;
    private byte maxval;

    BetterSorryState(byte[] v) {
        value = new AtomicIntegerArray(v.length);
        maxval = 127;
        for (int i = 0; i < v.length; i++) {
            value.set(i, v[i]);
        }
    }

    BetterSorryState(byte[] v, byte m) {
        value =new AtomicIntegerArray(v.length);
        maxval = m;
        for (int i = 0; i < v.length; i++) {
            value.set(i, v[i]);
        }
    }

    public int size() {
        return value.length();
    }

    public byte[] current() {
        byte byteArr[] = new byte[value.length()];
        for (int i = 0; i < byteArr.length; i++) {
            byteArr[i] = (byte) value.get(i);
        }
        return byteArr;
    }

    public boolean swap(int i, int j) {
        if (value.get(i) <= 0 || value.get(j) >= maxval) {
            return false;
        }

        value.decrementAndGet(i);
        value.incrementAndGet(j);
        return true;
    }
}