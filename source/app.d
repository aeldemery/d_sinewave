import gtk.ApplicationWindow;
import gtk.Label;
import gtk.Application;
import gio.Application: GioApplication = Application;
import gtk.DrawingArea, gtk.Widget;

import cairo.Context, cairo.Surface;

import glib.Timeout;

import std.math;





class SinWaveApp : Application {
this(string appId = "github.aeldemery.sinewave", GApplicationFlags flags = GApplicationFlags.FLAGS_NONE) {
    super(appId, flags);
}
}

class SineWaveWidget : DrawingArea {
immutable int PERIOD          = 100;
immutable int NUM_POINTS      = 1000;
static int current_width      = -1;
static int current_height     = -1;
static Surface current_source = null;
static Surface current_temp   = null;
static double last_x          = -1;
static double last_y          = -1;
static int redraw_number      = 0;

public this() {
    addEvents(
        EventMask.BUTTON_PRESS_MASK |
        EventMask.BUTTON_RELEASE_MASK |
        EventMask.POINTER_MOTION_MASK
        );
    addOnDraw(&draw);
    update();
    auto timeOut = new Timeout(1000 / 60, &update);
    //Timeout.add (cast(uint) 1000/60, &update, false);
}

public bool draw(Context context, Widget widget)
{
    int width  = getAllocatedWidth();
    int height = getAllocatedHeight();

    updateDrawing(width, height, context.getTarget());

    /* Draw the background */
    context.setSourceRgb(1, 1, 1);
    context.paint();

    /* Draw the content */
    context.setSourceSurface(current_source, 0, 0);
    context.paint();

    redraw_number++;
    return true;
}

void updateDrawing(int width, int height, Surface target)
{
    Context context;
    int     i;

    if (width != current_width || height != current_height)
    {
        current_width  = width;
        current_height = height;
        import cairo.c.types : cairo_content_t;
        current_source = target.createSimilar(cairo_content_t.COLOR, NUM_POINTS, height);
        current_temp   = target.createSimilar(cairo_content_t.COLOR, NUM_POINTS, height);

        context = Context.create(current_source);

        /* Redraw everything */

        /* Draw the background */
        context.setSourceRgb(1, 1, 1);
        context.paint();

        /* Draw a moving sine wave */
        context.setSourceRgb(0.5, 0.5, 0);
        context.moveTo(0, sineToPoint(0 + redraw_number, width, height));
        for (i = 1; i < NUM_POINTS; i++)
        {
            context.lineTo(i, sineToPoint(i + redraw_number, width, height));
        }
        context.getCurrentPoint(last_x, last_y);
        context.stroke();

        //cairo_destroy(context);
    }
    else
    {
        Surface temp;

        /* Move everything left and add a new data point */
        context = Context.create(current_temp);

        /* Scroll */
        context.setSourceSurface(current_source, -1, 0);
        context.paint();
        context.setSourceRgb(1, 1, 1);
        context.rectangle(NUM_POINTS - 1, 0, 1, height);
        context.fill();

        /* Add new point */
        context.setSourceRgb(0.5, 0.5, 0);
        context.moveTo(last_x - 1, last_y);
        context.lineTo(NUM_POINTS - 1, sineToPoint(NUM_POINTS + redraw_number, width, height));
        context.getCurrentPoint(last_x, last_y);
        context.stroke();

        /* Swap surfaces */
        temp           = current_temp;
        current_temp   = current_source;
        current_source = temp;
    }
}

bool update()
{
    queueDraw();
    return true;
}

/* gives error on release build "cant inline funktion"
pragma(inline, true)
*/
double sineToPoint(int x, int width, int height)
{
    return (height / 2.0) * sin(x * 2 * PI / PERIOD) + (height / 2);
}
}

class AppWindow : ApplicationWindow {
this(Application app) {
    super(app);
    setSizeRequest(600, 400);
    setPosition(WindowPosition.CENTER);

    auto sineWaveWidget = new SineWaveWidget();
    add(sineWaveWidget);
    showAll();
}
}

void main(string[] args)
{
    auto app = new SinWaveApp();
    app.addOnActivate(
        delegate void (GioApplication _) {
        auto win = app.getActiveWindow();
        if (win is null)
        {
            win = new AppWindow(app);
        }
        win.present();
    }
        );
    app.run(args);
}