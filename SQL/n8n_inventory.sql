-- Habilita la extensión pgvector
-- Si ya no usas pgvector, puedes omitir la extensión

-- Crear la tabla n8n_vector_inventory
-- Elimina índices y tabla si existen
DROP INDEX IF EXISTS idx_n8n_vector_inventory_embedding CASCADE;
DROP INDEX IF EXISTS idx_n8n_vector_inventory_nombre_locion CASCADE;
DROP INDEX IF EXISTS idx_n8n_vector_inventory_categoria CASCADE;
DROP INDEX IF EXISTS idx_n8n_vector_inventory_marca CASCADE;
DROP INDEX IF EXISTS idx_n8n_vector_inventory_disponible CASCADE;
DROP INDEX IF EXISTS idx_n8n_vector_inventory_precio CASCADE;
DROP TABLE IF EXISTS n8n_vector_inventory CASCADE;

-- Crear la nueva tabla n8n_inventory
CREATE TABLE IF NOT EXISTS n8n_inventory (
    id SERIAL PRIMARY KEY,
    nombre_locion VARCHAR(255) NOT NULL,
    descripcion_aroma VARCHAR(255),
    marca_fabricante VARCHAR(255),
    contenido_ml INTEGER,
    precio_venta INTEGER,
    categoria VARCHAR(50),
    disponible VARCHAR(10),
    imagen_principal VARCHAR(255),
    imagen_1 VARCHAR(255),
    imagen_2 VARCHAR(255),
    imagen_3 VARCHAR(255),
    url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar los datos del inventario
INSERT INTO n8n_inventory (
    nombre_locion, descripcion_aroma, marca_fabricante, contenido_ml, 
    precio_venta, categoria, disponible, imagen_principal, imagen_1, 
    imagen_2, imagen_3, url
) VALUES 
-- PRODUCTOS PARA HOMBRE
('ONE MILLION', 'dulce-amaderado', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '15nghbNGw8ucwN0fpPJiIbU57d4kwjEes', '', '', '', 'https://drive.google.com/file/d/15nghbNGw8ucwN0fpPJiIbU57d4kwjEes/view?usp=drivesdk'),
('INVICTUS', 'citrico-marino', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '1g3iZRmXr-Xg_XlqmMXLgaJJvQduQlZIH', '', '', '', 'https://drive.google.com/file/d/1g3iZRmXr-Xg_XlqmMXLgaJJvQduQlZIH/view?usp=drivesdk'),
('BLACK XS APHRODISIAQUE', 'dulce-amielado', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('SAUVAGE', 'cítrico-ambar', 'Dior', 100, 60000, 'HOMBRE', 'SI', '1DuZwGoZyDAKogGidLTtiXG8xA-YGPBVF', '', '', '', 'https://drive.google.com/file/d/1DuZwGoZyDAKogGidLTtiXG8xA-YGPBVF/view?usp=drivesdk'),
('INVICTUS VICTORY ELIXIR', 'avainillado-ambar', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('CREED SILVER', 'cítrico-aromático', 'Creed', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('212 MEN NYC', 'cítrico', 'Carolina Herrera', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('212 VIP BLACK', 'aromatico-avainillado', 'Carolina Herrera', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('BAD BOY', 'amaderado', 'Hugo Boss', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('UNLIMITED', 'cítrico', 'Hugo Boss', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('HUGO BOSS BOTTLED', 'amaderado-afrutado', 'Hugo Boss', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('BOSS NIGHT', 'cítrico-amaderado', 'Hugo Boss', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('HUGO MAN', 'aromática-fresco', 'Hugo Boss', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('HUGO RED', 'dulce', 'Hugo Boss', 100, 60000, 'HOMBRE', 'SI', '1QqknptcmId7MnUM3CndgPuDlBRrP7c6h', '', '', '', 'https://drive.google.com/file/d/1QqknptcmId7MnUM3CndgPuDlBRrP7c6h/view?usp=drivesdk'),
('BLACK L''EXCES', 'citrico-amaderado', 'Versace', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('VERSACE EROS', 'avainillado-aromatico', 'Versace', 100, 60000, 'HOMBRE', 'SI', '1jIKiFLa8gccbMAa6mTAleeM4Ov0xoE_K', '', '', '', 'https://drive.google.com/file/d/1jIKiFLa8gccbMAa6mTAleeM4Ov0xoE_K/view?usp=drivesdk'),
('EROS FLAME', 'amaderada-canela', 'Versace', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('FRAICHE', 'cítrico', 'Lacoste', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('LACOSTE RED', 'cítrico-amaderado', 'Lacoste', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('STARRY NIGHTS', 'cítrico-atalcado', 'Diesel', 120, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('ONLY THE BRAVE TATTOO', 'afrutado-tabaco', 'Diesel', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('ONLY THE BRAVE', 'ambar-citrico', 'Diesel', 75, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('PARIS MEN', 'tropical', 'Issey Miyake', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('ISSEY MIYAKE', 'cítrico', 'Issey Miyake', 125, 60000, 'HOMBRE', 'SI', '1WI-jev3g891h1nKTBr7mjqmJQgxQi0fx', '', '', '', 'https://drive.google.com/file/d/1WI-jev3g891h1nKTBr7mjqmJQgxQi0fx/view?usp=drivesdk'),
('FAHRENHEIT', 'amaderado', 'Dior', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('BLEU CHANEL', 'cítrico', 'Chanel', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('POLO BLUE', 'cítrico', 'Ralph Lauren', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('JEAN PAUL GAULTIER', 'avainillado', 'Jean Paul Gaultier', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('LEGEND SPIRIT', 'amaderado', 'Jean Paul Gaultier', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('INVICTUS INTENSE', 'ámbar', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('INVICTUS LEGEND', 'marino-aromático', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('MILLION PRIVE', 'amaderado-canela', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('212 VIP MEN', 'aromatico-vodka', 'Carolina Herrera', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('NAUTICA VOYAGE', 'cítrico', 'Nautica', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('LACOSTE BLANCA', 'cítrico', 'Lacoste', 100, 60000, 'HOMBRE', 'SI', '1Ww6qfVDS_904QANm58l1m2xS4LIy7zr6', '', '', '', 'https://drive.google.com/file/d/1Ww6qfVDS_904QANm58l1m2xS4LIy7zr6/view?usp=drivesdk'),
('LACOSTE NEGRA', 'cítrico-dulce', 'Lacoste', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('LACOSTE AZUL', 'cítrico', 'Lacoste', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('LACOSTE ROUGE', 'cítrico-amaderada', 'Lacoste', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('ACQUA DI GIO', 'cítrico-marino', 'Giorgio Armani', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('TOY BOY', 'dulce-amaderado', 'Moschino', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('PURE XS', 'dulce-amaderado', 'Prada', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('SWISS ARMY', 'cítrico-aromático', 'Swiss Army', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('CREED SANTAL', 'aromático-amaderado', 'Creed', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('MONT BLANC EMBLEM', 'aromático-acuático', 'Mont Blanc', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('CLINIQUE HAPPY', 'cítrico-marino', 'Clinique', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('MILLION LUCKY', 'dulce-amielado', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('212 SEXY MEN', 'avainillado-amaderado', 'Carolina Herrera', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('LIGHT MEN', 'citrico', 'Dolce & Gabbana', 125, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('OMBRE NOMADE', 'amaderado-ámbar', 'Louis Vuitton', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('INVICTUS AQUA', 'marino-ámbar', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('GIVENCHY EAU', 'Cítrico-fresco', 'Givenchy', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('CARTIER DECLARATION', 'Cítrico-amaderado', 'Cartier', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('ETERNITY', 'citrico-aromatico', 'Calvin Klein', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('CREED AVENTUS', 'Afrutado-dulce', 'Creed', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('JUST DIFFERENT', 'fresco-aromatico', 'Calvin Klein', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('CK ONE', 'Cítrico-amaderado', 'Calvin Klein', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('212 AQUA MEN', 'Calido-amaderado', 'Carolina Herrera', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('ROSES MUNK', 'Cítrico-floral', 'Roses Munk', 125, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('BVLGARI MAN', 'cálido-amaderado', 'Bvlgari', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('212 VIP BLACK RED', 'cálido-aromático', 'Carolina Herrera', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('THE ONE', 'cálido-ámbar', 'Dolce & Gabbana', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('360 RED FOR MEN', 'cítrico-fresco', 'Perry Ellis', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('CREED IMPERIAL', 'marino-cítrico', 'Creed', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('BVLGARI AQVA', 'acuático-cítrico', 'Bvlgari', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('INVICTUS VICTORY', 'avainillado-ámbar', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('ACQUA DI GIO PROFUMO', 'aromático-marino', 'Giorgio Armani', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('INVICTUS ONYX', 'cítrico-amaderado', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('360', 'aromático-amaderado', 'Perry Ellis', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('JEAN PAUL BE L''EAU', 'coco-dulce', 'Jean Paul Gaultier', 125, 60000, 'HOMBRE', 'SI', '1hx7vdo1m0JvHUksrlQGv9AWOYOOO6fRV', '', '', '', 'https://drive.google.com/file/d/1hx7vdo1m0JvHUksrlQGv9AWOYOOO6fRV/view?usp=drivesdk'),
('ROYAL AMBER', 'dulce', 'Genérico', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('AMBER ROUGE', 'maderoso', 'Genérico', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('OUD SAFFRON', 'amaderado', 'Genérico', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('STAWALKER', 'amaderado-citrico', 'Genérico', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('BLACK XS', 'dulce', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('VALENTINO UOMO', 'avainillado-lavanda', 'Valentino', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('TOMMY MEN', 'citrico-amaderado', 'Tommy Hilfiger', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('BLEU SEDUCTION', 'citrico-afrutado', 'Antonio Banderas', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('ARSENAL', 'citrico amaderado', 'Arsenal', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('SANTAL 33', 'amaderado-atalcado', 'Le Labo', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('PHANTOM', 'citrico-vainilla', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('PHANTOM PARFUM', 'aromatico-avainillado', 'Paco Rabanne', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('BHARARA KING', 'citrico citrico', 'Bharara', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('VELVET GOLD', '100 ML', 'Genérico', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('ARABIANS TONKA', 'dulce-avainillado', 'Genérico', 125, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('POLO RED', 'citrico-afrutado', 'Ralph Lauren', 125, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('BOSS THE SCENT', 'cítrico-cuero', 'Hugo Boss', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('LAPIDUS', 'amaderado-dulce', 'Ted Lapidus', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('ALHARAMAIN', 'dulce-frutal', 'Al Haramain', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('ALHARAMAIN ROUGE', 'ambar', 'Al Haramain', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('BHARARA KING', 'citrico aromatico', 'Bharara', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('LACOSTE GREEN', 'citrico aromatico', 'Lacoste', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('KHAMRAH', 'dulce-avainillado', 'Lattafa', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('SCANDAL MEN', 'Caramelo-aromatico', 'Jean Paul Gaultier', 100, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),
('LACOSTE ESSENTIAL', 'citrico-amaderado', 'Lacoste', 125, 60000, 'HOMBRE', 'SI', '', '', '', '', ''),

-- PRODUCTOS PARA MUJER
('GOOD GIRL', 'Dulce-avainillado', 'Carolina Herrera', 90, 60000, 'MUJER', 'SI', '1N_lVz--9iit1Vwo8IrPyLrc59E0_MBO9', '', '', '', 'https://drive.google.com/file/d/1N_lVz--9iit1Vwo8IrPyLrc59E0_MBO9/view?usp=drivesdk'),
('212 ROSE', 'Dulce-floral', 'Carolina Herrera', 80, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('CAN CAN', 'frutal-dulce', 'Paris Hilton', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('CHANCE CHANEL', 'Cítrica', 'Chanel', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('FANTASTIC PINK', 'dulce-avainillado', 'Genérico', 90, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('STARRY NIGHTS', 'cítrico', 'Diesel', 120, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('OLYMPEA', 'avainillado-floral', 'Paco Rabanne', 80, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('PARIS HILTON', 'dulce-frutal', 'Paris Hilton', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('FANTASY', 'dulce-frutal', 'Britney Spears', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('RALPH', 'floral-frutal', 'Ralph Lauren', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('360 FEM', 'Dulce-fresco', 'Perry Ellis', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('BRIGHT CRYSTAL', 'Floral-afrutado', 'Versace', 90, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('YELLOW DIAMOND', 'cítrico-floral', 'Versace', 90, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('MISS DIOR', 'amaderado-afrutado', 'Dior', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('OMNIA CRYSTALLINE', 'cítrico', 'Bvlgari', 65, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('OMNIA CORAL', 'cítrico-floral', 'Bvlgari', 65, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('CH FEM', 'cítrico-frutal', 'Carolina Herrera', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('COCO MADEMOISELLE', 'amaderada', 'Chanel', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('LA VIDA ES BELLA', 'dulce-amaderada', 'Lancôme', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('LACOSTE TOUCH PINK', 'cítrico-dulce', 'Lacoste', 90, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('TOY 2', 'afrutado-floral', 'Moschino', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('ARABIANS TONKA', 'dulce-avainillado', 'Genérico', 125, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('MEOW', 'dulce-avainillado', 'Katy Perry', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('SCANDAL', 'amaderado', 'Jean Paul Gaultier', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('J''ADORE', 'floral-frutal', 'Dior', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('ROSES MUSK', 'floral-rosas', 'Roses Munk', 125, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('AGUA DE SOL', 'afrutado-dulce', 'Escada', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('BUBBLE GUM', 'afrutado-dulce', 'Genérico', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('LIGHT BLUE', 'cítrico-afrutado', 'Dolce & Gabbana', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('TOMMY GIRL', 'cítrico-floral', 'Tommy Hilfiger', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('BLACK XS FOR HER', 'cálido-cacao', 'Paco Rabanne', 80, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('FUNNY MOSCHINO', 'cítrico-fresco', 'Moschino', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('VERY GOOD', 'afrutado-rosa', 'Genérico', 80, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('212 VIP ROSE RED', 'Dulce', 'Carolina Herrera', 80, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('360 RED MUJER', 'Floral', 'Perry Ellis', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('AMBER ROUGE', 'maderoso', 'Genérico', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('ROYAL AMBER', 'dulce', 'Genérico', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('VELVET GOLD', 'dulce', 'Genérico', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('ANGEL Y DEMONIO', 'amaderada', 'Givenchy', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('212 SEXY', 'dulce-atalcado', 'Carolina Herrera', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('DAZZLE', 'dulce-floral', 'Marc Ecko', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('BURBERRY', 'amaderado-afrutado', 'Burberry', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('BOMBSHELL', 'dulce-afrutado', 'Victoria''s Secret', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('212 WILD PARTY', 'dulce-afrutado', 'Carolina Herrera', 80, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('LADY MILLION', 'dulce', 'Paco Rabanne', 80, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('SANTAL 33', 'amaderado-atalcado', 'Le Labo', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('212 FEM', 'citrico', 'Carolina Herrera', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('BHARARA NICHE', 'amaderado-chocolate', 'Bharara', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('CLASSIQUE', 'floral-dulce', 'Jean Paul Gaultier', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('CHANCE EAU FRAICHE', 'citrica', 'Chanel', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('CK ONE', 'citrica', 'Calvin Klein', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('PARIS HEIRESS', 'afrutado-dulce', 'Paris Hilton', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('THE ONE', 'floral', 'Dolce & Gabbana', 75, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('ROSE RUSH PARIS', 'floral-tropical', 'Paris Hilton', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('212 VIP', 'avainillado-ron', 'Carolina Herrera', 80, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('BOSS THE SCENT', 'Floral-afrutado', 'Hugo Boss', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('FAME', 'tropical-vainilla', 'Lady Gaga', 80, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('DELINA', 'rosa-floral', 'Parfums de Marly', 75, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('360 CORAL', 'afrutado-fresco', 'Perry Ellis', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('LACOSTE NATURAL', 'dulce afrutado', 'Lacoste', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('LACOSTE SPARKLING', 'dulce-citrico', 'Lacoste', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('LACOSTE ELEGANT', 'fresco-atalcado', 'Lacoste', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('LOVE LOVE', 'Citrico', 'Moschino', 75, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('FRESH COUTURE', 'Rosas-Cítrico', 'Moschino', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('ISSEY FEM', 'acuatico-floral', 'Issey Miyake', 100, 60000, 'MUJER', 'SI', '', '', '', '', ''),
('CHANEL #5', 'amaderado-fresco', 'Chanel', 100, 60000, 'MUJER', 'SI', '', '', '', '', '');

CREATE INDEX idx_n8n_inventory_nombre_locion ON n8n_inventory(nombre_locion);
CREATE INDEX idx_n8n_inventory_categoria ON n8n_inventory(categoria);
CREATE INDEX idx_n8n_inventory_marca ON n8n_inventory(marca_fabricante);
CREATE INDEX idx_n8n_inventory_disponible ON n8n_inventory(disponible);
CREATE INDEX idx_n8n_inventory_precio ON n8n_inventory(precio_venta);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_n8n_inventory_updated_at 
    BEFORE UPDATE ON n8n_inventory 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Consultas de ejemplo para verificar los datos
-- SELECT COUNT(*) FROM n8n_vector_inventory;
-- SELECT categoria, COUNT(*) FROM n8n_vector_inventory GROUP BY categoria;
-- SELECT marca_fabricante, COUNT(*) FROM n8n_vector_inventory GROUP BY marca_fabricante ORDER BY COUNT(*) DESC;