package ec.edu.uce.soundstream;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.regex.Pattern;

/**
 * GET /api/audio/{id}
 * Tomcat solo AUTORIZA: con sesion valida responde 200 sin cuerpo y la cabecera
 * X-Accel-Redirect; Nginx entrega el archivo (HTTP Range / 206) desde su volumen.
 * Sin sesion responde 401.
 */
@WebServlet("/api/audio/*")
public class AudioAuthServlet extends HttpServlet {

    // TODO: confirmar con Integrante 3 la ruta interna (location "internal" en Nginx)
    private static final String INTERNAL_PREFIX = "/protected-media/";
    private static final Pattern VALID_ID = Pattern.compile("^[A-Za-z0-9_-]{1,64}$");

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            resp.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Sesion requerida");
            return;
        }

        String path = req.getPathInfo();
        String id = (path == null || path.length() < 2) ? "" : path.substring(1);
        if (!VALID_ID.matcher(id).matches()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Identificador de audio invalido");
            return;
        }

        // TODO: consultar en PostgreSQL el archivo real asociado al id
        resp.setStatus(HttpServletResponse.SC_OK);
        resp.setHeader("X-Accel-Redirect", INTERNAL_PREFIX + id + ".mp3");
    }
}
