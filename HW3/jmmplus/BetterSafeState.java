import java.util.concurrent.locks.ReentrantLock;

class BetterSafeState implements State {
    private byte[] value;
    private byte maxval;

    // Create new lock                                                               
    private final ReentrantLock l = new ReentrantLock();

    BetterSafeState(byte[] v) { value = v; maxval = 127; }

    BetterSafeState(byte[] v, byte m) { value = v; maxval = m; }

    public int size() { return value.length; }

    public byte[] current() { return value; }

    public boolean swap(int i, int j) {


        // Lock                                                                      
        l.lock();

        try {
            if (value[i] <= 0 || value[j] >= maxval) {
                return false;
            }
            value[i]--;
            value[j]++;
            return true;
        }
        // unlock l. The finally block is used to ensure that l is unlocked even if the try block returns                                                                
        finally {
            l.unlock();
        }
    }
}