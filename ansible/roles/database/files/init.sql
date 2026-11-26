-- 1. Tabla de Usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username        VARCHAR(50)  NOT NULL UNIQUE,
    email           VARCHAR(120) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    rol             VARCHAR(20)  NOT NULL DEFAULT 'USER' CHECK (rol IN ('USER', 'ADMIN')),
    activo          BOOLEAN      NOT NULL DEFAULT TRUE,
    creado_en       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- 2. Tabla de Artistas
CREATE TABLE IF NOT EXISTS artistas (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR(120) NOT NULL UNIQUE,
    biografia       TEXT,
    imagen_archivo  VARCHAR(255) DEFAULT 'default_artist.jpg',
    creado_en       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- 3. Tabla de Álbumes
CREATE TABLE IF NOT EXISTS albumes (
    id               INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titulo           VARCHAR(150) NOT NULL,
    artista_id       INTEGER      NOT NULL REFERENCES artistas(id) ON DELETE CASCADE,
    anio_lanzamiento INTEGER      CHECK (anio_lanzamiento >= 1900 AND anio_lanzamiento <= 2100),
    portada_archivo  VARCHAR(255) NOT NULL DEFAULT 'default_cover.jpg',
    creado_en        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_album_artista UNIQUE (artista_id, titulo)
);

-- 4. Tabla de Canciones
CREATE TABLE IF NOT EXISTS canciones (
    id                INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titulo            VARCHAR(150) NOT NULL,
    artista_id        INTEGER      NOT NULL REFERENCES artistas(id) ON DELETE CASCADE,
    album_id          INTEGER      REFERENCES albumes(id) ON DELETE SET NULL,
    numero_pista      INTEGER      DEFAULT 1 CHECK (numero_pista > 0),
    duracion_segundos INTEGER      NOT NULL CHECK (duracion_segundos > 0),
    archivo_audio     VARCHAR(255) NOT NULL UNIQUE,
    mime_type         VARCHAR(50)  NOT NULL DEFAULT 'audio/mpeg',
    tamano_bytes      BIGINT       NOT NULL CHECK (tamano_bytes > 0),
    reproducciones    BIGINT       NOT NULL DEFAULT 0,
    creado_en         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_cancion_artista UNIQUE (artista_id, titulo)
);

-- 5. Tabla de Playlists
CREATE TABLE IF NOT EXISTS playlists (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    usuario_id      INTEGER      NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    publica         BOOLEAN      NOT NULL DEFAULT FALSE,
    creado_en       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- 6. Tabla Intermedia Playlist <-> Canciones
CREATE TABLE IF NOT EXISTS playlist_canciones (
    playlist_id     INTEGER     NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
    cancion_id      INTEGER     NOT NULL REFERENCES canciones(id) ON DELETE CASCADE,
    orden           INTEGER     NOT NULL DEFAULT 1,
    agregado_en     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (playlist_id, cancion_id)
);

-- Índices para acelerar búsquedas
CREATE INDEX IF NOT EXISTS idx_albumes_artista_id   ON albumes(artista_id);
CREATE INDEX IF NOT EXISTS idx_canciones_artista_id ON canciones(artista_id);
CREATE INDEX IF NOT EXISTS idx_canciones_album_id   ON canciones(album_id);
CREATE INDEX IF NOT EXISTS idx_canciones_titulo     ON canciones(titulo);
CREATE INDEX IF NOT EXISTS idx_playlists_usuario_id ON playlists(usuario_id);

-- Datos de prueba iniciales
INSERT INTO usuarios (username, email, password_hash, rol)
VALUES 
    ('admin_sound', 'admin@soundstream.ec', '$2a$10$EjemploHashBcryptAdmin1234567890123456789012', 'ADMIN'),
    ('oyente_uce',  'estudiante@uce.edu.ec', '$2a$10$EjemploHashBcryptUser1234567890123456789012', 'USER')
ON CONFLICT (username) DO NOTHING;

INSERT INTO artistas (nombre, biografia, imagen_archivo)
VALUES 
    ('Quito Synth Collective', 'Proyecto experimental de electrónica y ambient desde los Andes.', 'artist_quito_synth.jpg'),
    ('Andes Lo-Fi Beats', 'Producciones instrumentales para sesiones de estudio y código.', 'artist_andes_lofi.jpg')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO albumes (titulo, artista_id, anio_lanzamiento, portada_archivo)
SELECT 'Noches en el Pichincha', id, 2026, 'cover_pichincha.jpg'
FROM artistas WHERE nombre = 'Quito Synth Collective'
ON CONFLICT (artista_id, titulo) DO NOTHING;

INSERT INTO albumes (titulo, artista_id, anio_lanzamiento, portada_archivo)
SELECT 'Compilando de Madrugada', id, 2026, 'cover_compilando.jpg'
FROM artistas WHERE nombre = 'Andes Lo-Fi Beats'
ON CONFLICT (artista_id, titulo) DO NOTHING;

INSERT INTO canciones (titulo, artista_id, album_id, numero_pista, duracion_segundos, archivo_audio, mime_type, tamano_bytes)
SELECT 'Teleférico a Medianoche', a.id, al.id, 1, 215, 'demo_teleferico.mp3', 'audio/mpeg', 5160960
FROM artistas a JOIN albumes al ON al.artista_id = a.id
WHERE a.nombre = 'Quito Synth Collective' AND al.titulo = 'Noches en el Pichincha'
ON CONFLICT (archivo_audio) DO NOTHING;

INSERT INTO canciones (titulo, artista_id, album_id, numero_pista, duracion_segundos, archivo_audio, mime_type, tamano_bytes)
SELECT 'Kernel Panic Chill', a.id, al.id, 1, 184, 'demo_kernel_panic.mp3', 'audio/mpeg', 4417536
FROM artistas a JOIN albumes al ON al.artista_id = a.id
WHERE a.nombre = 'Andes Lo-Fi Beats' AND al.titulo = 'Compilando de Madrugada'
ON CONFLICT (archivo_audio) DO NOTHING;
