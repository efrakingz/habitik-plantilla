import '../models/models.dart';

final List<TriviaQuestion> triviaQuestions = [
  TriviaQuestion(
    pregunta: '¿Cuántos litros de agua promedio consume una ducha de 10 minutos en Chile?',
    opciones: ['30 a 50 litros', '80 a 100 litros', '150 a 180 litros', 'Más de 250 litros'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué electrodoméstico consume más electricidad estando apagado pero enchufado (consumo vampiro)?',
    opciones: ['Cargador de celular', 'Consola de videojuegos en standby', 'Hervidor eléctrico', 'Foco LED de noche'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es la tarifa eléctrica residencial base más común en Chile?',
    opciones: ['Tarifa DAC', 'Tarifa 1A', 'Tarifa BT1', 'Tarifa Residencial Alta'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué porcentaje del consumo eléctrico de un hogar promedio chileno se debe al standby o "consumo vampiro"?',
    opciones: ['Menos del 1%', 'Entre 5% y 10%', 'Aproximadamente el 25%', 'Más del 40%'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuánta agua al mes puede desperdiciar un inodoro con una fuga leve continua?',
    opciones: ['Hasta 50 litros', 'Hasta 500 litros', 'Hasta 1.000 litros', 'Más de 10.000 litros'],
    correcta: 3,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál de los siguientes materiales tarda más tiempo en degradarse en la naturaleza?',
    opciones: ['Botella de vidrio', 'Bolsa de plástico', 'Caja de cartón', 'Lata de aluminio'],
    correcta: 0,
  ),
  TriviaQuestion(
    pregunta: '¿Qué tipo de ampolleta consume un 80% menos de energía y dura hasta 10 veces más?',
    opciones: ['Ampolleta halógena', 'Ampolleta incandescente', 'Foco LED', 'Tubo fluorescente antiguo'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué gas de efecto invernadero se produce en gran medida en los vertederos por la basura orgánica?',
    opciones: ['Dióxido de carbono', 'Metano', 'Óxido nitroso', 'Ozono'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuánto gasta promedio por hora un hervidor eléctrico promedio de 2000W?',
    opciones: ['0.2 kWh', '1.0 kWh', '2.0 kWh', '5.0 kWh'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es el beneficio principal del compostaje casero?',
    opciones: ['Producir plástico biodegradable', 'Reducir a la mitad la basura que va al vertedero', 'Generar gas natural', 'Limpiar el agua de lluvia'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué se debe hacer con una botella PET antes de llevarla al contenedor de reciclaje?',
    opciones: ['Lavarla, quitarle la tapa y aplastarla', 'Cortarla por la mitad', 'Pintarla', 'Llenarla con arena'],
    correcta: 0,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál de estos objetos NO debe ir al contenedor de reciclaje de vidrio?',
    opciones: ['Botella de refresco', 'Frasco de mermelada', 'Espejos o parabrisas de auto', 'Ampolleta de luz natural'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué organismo regula las tarifas y calidad de los servicios sanitarios (agua) en Chile?',
    opciones: ['SISS', 'SEC', 'CNE', 'Ministerio de Energía'],
    correcta: 0,
  ),
  TriviaQuestion(
    pregunta: '¿Qué organismo fiscaliza las instalaciones eléctricas y de gas en el hogar chileno?',
    opciones: ['SISS', 'SEC', 'CNE', 'Conaf'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuánta agua desperdicias al cepillarte los dientes con la llave abierta durante 3 minutos?',
    opciones: ['Alrededor de 5 litros', 'Alrededor de 12 litros', 'Alrededor de 36 litros', 'Alrededor de 80 litros'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es la mejor hora del día para regar las plantas del jardín y evitar evaporación?',
    opciones: ['A las 12:00 del mediodía', 'A las 3:00 de la tarde', 'Al amanecer o al anochecer', 'A media mañana'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué tipo de residuo se clasifica de color rojo en la normativa de reciclaje estándar?',
    opciones: ['Vidrio', 'Pilas y baterías (peligrosos)', 'Papel y cartón', 'Plásticos PET'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuánto gasta la secadora de ropa promedio por ciclo completo?',
    opciones: ['Menos de 0.5 kWh', 'Alrededor de 1 kWh', 'Entre 2 y 3 kWh', 'Más de 10 kWh'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué material de reciclaje se puede fundir y reutilizar infinitas veces sin perder calidad?',
    opciones: ['Plástico PET', 'Papel periódico', 'Vidrio', 'Cartón Tetra Pak'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué tipo de calefacción domiciliaria genera mayor huella de carbono y contaminación intradomiciliaria?',
    opciones: ['Aire acondicionado inverter', 'Estufa a leña convencional', 'Radiador eléctrico', 'Estufa a parafina láser'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué significa el concepto de "Huella de Carbono"?',
    opciones: ['La marca física del carbón', 'La cantidad de gases de efecto invernadero liberados por nuestras actividades', 'El hollín acumulado en las chimeneas', 'La cantidad de árboles plantados en un año'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué porcentaje del planeta está cubierto por agua dulce utilizable para los humanos?',
    opciones: ['Aproximadamente el 70%', 'Alrededor del 10%', 'Menos del 1%', 'Cerca del 25%'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Cómo se llama el cobro adicional que aplican las sanitarias chilenas en meses de verano por alto consumo?',
    opciones: ['Tarifa no punta', 'Cargo por sobreconsumo', 'Multa estival', 'Cargo de alcantarillado doble'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál de estos residuos es excelente para la capa "marrón" o seca del compost?',
    opciones: ['Hojas secas y cartón picado', 'Restos de manzana fresca', 'Cáscaras de naranja húmedas', 'Corte de pasto verde recién hecho'],
    correcta: 0,
  ),
  TriviaQuestion(
    pregunta: '¿Qué elemento NO se debe introducir jamás en una compostera casera?',
    opciones: ['Cáscaras de plátano', 'Bolsas de té de papel', 'Restos de carne, grasa o lácteos', 'Carozo de durazno'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué gas de efecto invernadero retiene hasta 25 veces más calor en la atmósfera que el dióxido de carbono?',
    opciones: ['Metano', 'Helio', 'Oxígeno', 'Nitrógeno'],
    correcta: 0,
  ),
  TriviaQuestion(
    pregunta: '¿Qué tipo de plástico es el PET (Número 1)?',
    opciones: ['Polietileno Tereftalato', 'Poliestireno expandido', 'Cloruro de polivinilo', 'Polipropileno'],
    correcta: 0,
  ),
  TriviaQuestion(
    pregunta: '¿Cuántos árboles se salvan aproximadamente al reciclar una tonelada de papel?',
    opciones: ['2 árboles', '5 árboles', '17 árboles', '100 árboles'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué consume más energía en una lavadora de ropa?',
    opciones: ['El giro del tambor para exprimir', 'El sistema de calentamiento de agua', 'La bomba de desagüe', 'El tablero digital'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué beneficio ambiental tienen las bolsas reutilizables de tela?',
    opciones: ['Son más coloridas', 'Reemplazan cientos de bolsas de plástico de un solo uso', 'Se biodegradan en un día', 'No tienen beneficio real'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué electrodoméstico es considerado el "rey del consumo" en invierno en los hogares chilenos?',
    opciones: ['Hervidor de agua', 'Aspiradora', 'Refrigerador', 'Estufa eléctrica tradicional'],
    correcta: 3,
  ),
  TriviaQuestion(
    pregunta: '¿Cómo afecta tener el refrigerador lleno al límite de su capacidad?',
    opciones: ['Ahorra energía porque acumula frío', 'Obliga al motor a trabajar más y consume más electricidad', 'No tiene ningún efecto térmico', 'Conserva mejor los plásticos'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué distancia mínima recomendable debe haber entre el refrigerador y la pared para evitar sobreconsumo?',
    opciones: ['Pegado por completo', 'Unos 10 a 15 centímetros para disipar el calor', 'Mínimo un metro', 'No influye en el consumo'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es la función principal de la capa de ozono?',
    opciones: ['Regular las mareas', 'Bloquear la radiación ultravioleta del sol', 'Producir oxígeno para la lluvia', 'Limpiar el aire de gases nocivos'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué elemento químico de los refrigeradores antiguos dañaba gravemente la capa de ozono?',
    opciones: ['Clorofluorocarbonos (CFC)', 'Dióxido de carbono', 'Metano', 'Plomo'],
    correcta: 0,
  ),
  TriviaQuestion(
    pregunta: '¿Qué tipo de energía renovable se obtiene del calor interno de la Tierra?',
    opciones: ['Energía solar', 'Energía eólica', 'Energía geotérmica', 'Biomasa'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué tipo de energía renovable aprovecha el movimiento de las mareas?',
    opciones: ['Energía undimotriz', 'Energía mareomotriz', 'Energía hidráulica', 'Energía eólica offshore'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué combustible fósil es el más contaminante al quemarse para producir electricidad?',
    opciones: ['Gas natural', 'Petróleo diésel', 'Carbón mineral', 'Gas licuado'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es la principal fuente de contaminación acústica en las ciudades chilenas?',
    opciones: ['El tránsito vehicular', 'Las obras de construcción', 'Los gritos de las personas', 'Las mascotas'],
    correcta: 0,
  ),
  TriviaQuestion(
    pregunta: '¿Qué es el "microplástico"?',
    opciones: ['Un plástico muy delgado', 'Partículas plásticas de menos de 5 mm que contaminan ecosistemas', 'Un tipo de juguete plástico', 'Una marca de envase biodegradable'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué significa la regla ecológica de las "3R"?',
    opciones: ['Recoger, Reconstruir, Revalorizar', 'Reducir, Reutilizar, Reciclar', 'Revisar, Reparar, Rediseñar', 'Rápido, Rendidor, Responsable'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál de las "3R" es la más importante para cuidar el medio ambiente?',
    opciones: ['Reciclar (procesar los desechos)', 'Reutilizar (darles otra vida)', 'Reducir (evitar generar el desecho)', 'Las tres tienen idéntico impacto estructural'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué gas es el responsable del 70% del efecto invernadero causado por el hombre?',
    opciones: ['Metano', 'Dióxido de Carbono (CO2)', 'Vapor de agua', 'Óxido de nitrógeno'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuánto m³ de agua promedio consume una persona al mes bajo estándares eficientes?',
    opciones: ['Entre 1 y 2 m³', 'Entre 4 y 5 m³', 'Más de 15 m³', 'Cerca de 50 m³'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué material de envase es conocido como Tetra Pak?',
    opciones: ['Poliestireno de alta densidad', 'Un envase compuesto de cartón, aluminio y plástico', 'Un tipo de vidrio templado reciclado', 'Plástico biodegradable de maíz'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué se debe evitar con el aceite de cocina usado?',
    opciones: ['Verterlo por el desagüe o lavaplatos', 'Llevarlo a puntos limpios especializados', 'Hacer jabón casero con él', 'Reutilizarlo en ensaladas'],
    correcta: 0,
  ),
  TriviaQuestion(
    pregunta: '¿Cuántos litros de agua potable puede contaminar un solo litro de aceite de cocina vertido en el desagüe?',
    opciones: ['Hasta 10 litros', 'Alrededor de 100 litros', 'Alrededor de 1.000 litros', 'Cerca de 1.000.000 de litros'],
    correcta: 3,
  ),
  TriviaQuestion(
    pregunta: '¿Qué animal está protegido legalmente en Chile por su rol en el control de plagas y polinización?',
    opciones: ['Pájaro carpintero', 'El abejorro chileno y los murciélagos', 'La paloma común', 'El gorrión'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es la función principal de los humedales en las costas chilenas?',
    opciones: ['Atraer turistas', 'Filtrar el agua, retener inundaciones y proteger la biodiversidad', 'Servir de depósito para desechos inertes', 'Secar la humedad costera'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué bosque nativo de Chile es considerado monumento natural y puede vivir más de 3.000 años?',
    opciones: ['Pino radiata', 'Eucalipto', 'Alerce (Lahuán)', 'Álamo'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Cómo ayuda abrir las cortinas y aprovechar el sol en invierno al consumo del hogar?',
    opciones: ['No influye en la boleta', 'Aumenta el frío por radiación solar', 'Atempera la casa de forma natural reduciendo el uso de calefactores', 'Daña los muebles'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué tipo de aire acondicionado es el más eficiente en consumo energético?',
    opciones: ['Aire acondicionado portátil convencional', 'Aire acondicionado con tecnología Inverter', 'Enfriador de aire por agua', 'Ventilador de techo tradicional'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿A qué temperatura se recomienda configurar el aire acondicionado en verano para un consumo eficiente?',
    opciones: ['A 16 grados Celsius', 'A 24 grados Celsius', 'A 28 grados Celsius', 'A la menor posible'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué material NO es biodegradable?',
    opciones: ['Restos de comida', 'Madera al natural', 'Telgopor / Poliestireno Expandido', 'Lino o algodón'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Cuánta energía ahorra aproximadamente una lavadora si se lava con agua fría en lugar de agua caliente?',
    opciones: ['Apenas un 5%', 'Entre un 15% y 25%', 'Entre un 80% y 90%', 'No hay diferencia en energía'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué es el compost?',
    opciones: ['Una marca de plástico para envase', 'Abono orgánico rico en nutrientes resultante de la descomposición controlada de residuos', 'Basura de baño comprimida', 'Un limpiador químico biodegradable'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál de estos desechos de cocina es un residuo orgánico "verde" (rico en nitrógeno)?',
    opciones: ['Filtros de café de papel', 'Cáscaras de frutas y verduras frescas', 'Aserrín de madera limpia', 'Cajas de huevo de cartón molidas'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué provoca el exceso de humedad en una compostera?',
    opciones: ['Acelera el proceso sin efectos secundarios', 'Falta de oxígeno, pudrición y malos olores', 'Secado absoluto del material orgánico', 'Aparición de flores nativas'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es el principal problema de las pilas comunes botadas a la basura convencional?',
    opciones: ['Se degradan muy rápido y ensucian', 'Liberan metales pesados altamente tóxicos como mercurio y cadmio que contaminan el suelo y napas de agua', 'Pueden provocar explosiones en el camión de basura', 'Atraen insectos nocivos'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es la forma más ecológica de secar la ropa en los hogares?',
    opciones: ['Usar la secadora eléctrica en ciclo rápido', 'Colgar la ropa en un tendedero al sol y viento', 'Colocarla encima de estufas a gas', 'Usar plancha de ropa húmeda'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué gas de efecto invernadero liberan los automóviles a gasolina?',
    opciones: ['Metano', 'Dióxido de carbono (CO2)', 'Helio', 'Oxígeno'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cómo ayuda plantar especies nativas en nuestro patio o antejardín?',
    opciones: ['Requieren mucho más cuidado y agua', 'Atraen plagas de insectos exóticos', 'Están adaptadas al clima local y consumen mucha menos agua que el césped común', 'Dificultan el crecimiento del pasto nativo'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué dispositivo nos permite apagar múltiples vampiros de energía con un solo botón?',
    opciones: ['Un interruptor magnetotérmico', 'Un alargador o zapatilla eléctrica con interruptor rojo', 'El medidor de luz de la calle', 'Un enchufe hembra tradicional'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué se debe revisar en la boleta mensual de luz para saber si nuestro consumo subió respecto al año pasado?',
    opciones: ['El total a pagar en pesos', 'El gráfico de barras de consumo histórico en kWh', 'La fecha de vencimiento del recibo', 'El número de cliente de la cuenta'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es el beneficio de la tecnología Inverter en los electrodomésticos?',
    opciones: ['Cambia el diseño exterior', 'Permite que el motor funcione de forma continua y eficiente sin arranques bruscos, ahorrando hasta un 40% de energía', 'Hace que se enfríen más rápido las rejillas', 'Reduce el peso de los equipos'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuánta energía gasta un cargador de celular enchufado a la pared sin tener conectado el teléfono?',
    opciones: ['Nada en absoluto', 'Alrededor de 0.1 a 0.5 Watts constantes en vacío', 'Más de 10 Watts por minuto', 'Igual que si estuviera cargando el celular'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué es el "Efecto Invernadero" natural?',
    opciones: ['Un proceso dañino creado por las fábricas en el siglo XX', 'Un fenómeno natural que mantiene la temperatura de la Tierra en niveles aptos para la vida', 'El calentamiento de las plantas en viveros cerrados', 'La radiación del sol al chocar con las nubes grises'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué sector productivo a nivel global produce la mayor cantidad de emisiones de gases de efecto invernadero?',
    opciones: ['La generación de electricidad y calor a partir de combustibles fósiles', 'La aviación comercial de pasajeros', 'La industria textil de moda rápida', 'La minería de oro y plata'],
    correcta: 0,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es la función ecológica de las abejas y abejorros en la naturaleza?',
    opciones: ['Producir miel para los humanos únicamente', 'La polinización de plantas y flores, vital para la producción de alimentos', 'Limpiar las hojas secas de los árboles', 'Controlar la población de mariposas'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cómo afecta verter detergentes convencionales no biodegradables al lavar la loza o ropa?',
    opciones: ['No afecta porque el agua se evapora', 'Contamina ríos y lagos provocando la muerte de peces y la proliferación de algas nocivas', 'Mejora la calidad de los lodos en alcantarillas', 'Limpia las algas de las cuencas fluviales'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué alternativa casera es ideal para limpiar vidrios y superficies sin usar químicos industriales?',
    opciones: ['Una mezcla de agua con cloro concentrado', 'Una mezcla de agua con vinagre blanco y bicarbonato', 'Aceite de oliva puro', 'Detergente líquido de ropa concentrado'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cómo contribuye el uso de la bicicleta o caminar a la sustentabilidad urbana?',
    opciones: ['Genera desgaste en las calles residenciales', 'Reduce las emisiones de gases de efecto invernadero, descongestiona el tráfico y mejora la salud', 'Incrementa la radiación en ciclistas', 'No tiene impacto sustentable medible'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué problema ambiental provocan los envases de plástico de un solo uso en los océanos?',
    opciones: ['Se hunden y crean arrecifes seguros', 'Se fragmentan en microplásticos que asfixian y envenenan a la fauna marina e ingresan a la cadena alimenticia', 'Aumentan la salinidad del agua costera', 'Enfrían las corrientes de agua marina'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es la vida útil promedio de una bolsa de plástico de supermercado antes de ser desechada?',
    opciones: ['Alrededor de 15 minutos', 'Aproximadamente una semana', 'Cerca de un año', 'Varios años'],
    correcta: 0,
  ),
  TriviaQuestion(
    pregunta: '¿Cuánto tiempo aproximado tarda una botella de plástico de refresco en degradarse por completo?',
    opciones: ['Cerca de 5 años', 'Cerca de 50 años', 'Hasta 500 años', 'Se biodegrada en menos de un mes'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué tipo de ampolletas tradicionales consumen la mayor cantidad de energía liberando calor?',
    opciones: ['Ampolletas incandescentes antiguas', 'Focos LED modernos', 'Tubos fluorescentes eficientes', 'Ampolletas halógenas compactas'],
    correcta: 0,
  ),
  TriviaQuestion(
    pregunta: '¿Qué es la biomasa como fuente de energía?',
    opciones: ['La fuerza del oleaje del mar', 'Materia orgánica biodegradable utilizada como combustible para generar energía', 'La masa de los animales del planeta', 'Un tipo de gas artificial de laboratorio'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál de las siguientes acciones individuales ahorra la mayor cantidad de agua potable en el hogar?',
    opciones: ['Usar el lavavajillas a media carga', 'Cerrar la llave del agua durante el cepillado de dientes y acortar la ducha a 5 minutos', 'Barrer el patio con la manguera abierta en chorro suave', 'Lavar el auto una vez al día con balde'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué gas es indispensable para que las plantas realicen la fotosíntesis y produzcan oxígeno?',
    opciones: ['Metano', 'Dióxido de carbono (CO2)', 'Helio', 'Monóxido de carbono'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué sucede si dejamos el termo eléctrico encendido las 24 horas del día a máxima temperatura?',
    opciones: ['Ahorramos energía al mantener el calor inicial', 'Desperdiciamos electricidad para reponer las pérdidas constantes de calor residual a través de las paredes del termo', 'El agua se evapora dentro del calefactor', 'El consumo se congela al estabilizarse'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es el beneficio de colocar aireadores o difusores en los grifos y llaves de agua?',
    opciones: ['Aumenta el caudal consumido duplicando el chorro', 'Mezclan el agua con aire reduciendo el consumo de agua hasta en un 50% sin perder presión de salida', 'Pintan el agua de color ecológico', 'Evitan que salgan minerales nocivos del caño'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál de estos envases NO se debe colocar en el contenedor de papeles y cartón?',
    opciones: ['Caja de cereal seca', 'Caja de pizza manchada con grasa y restos de queso adheridos', 'Rollo interior de papel higiénico', 'Sobre de correspondencia sin plástico'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Por qué la grasa y el aceite inhabilitan el reciclaje del papel y cartón?',
    opciones: ['Porque manchan las manos de los recolectores', 'Porque interfieren en el proceso de separación de fibras de celulosa con agua durante el reciclaje', 'Porque desprenden olores agradables', 'Porque atraen insectos que dañan el aluminio'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué es el desarrollo sustentable?',
    opciones: ['Aquel que solo busca el crecimiento económico ilimitado', 'Aquel que satisface las necesidades del presente sin comprometer la capacidad de las futuras generaciones', 'Un plan de desarrollo para viveros de plantas medicinales', 'Aquel enfocado solo en el cuidado animal sin intervención humana'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué tipo de bolsa plástica está prohibida por ley en el comercio y supermercados en Chile?',
    opciones: ['Bolsas reutilizables de tela', 'Bolsas de plástico de un solo uso para transportar mercancías', 'Bolsas de basura industriales', 'Bolsas para empaquetar alimentos a granel húmedos'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué porcentaje de la basura doméstica promedio de un hogar está compuesto por residuos orgánicos compostables?',
    opciones: ['Apenas un 5%', 'Cerca del 15%', 'Aproximadamente el 50%', 'Más del 90%'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Cómo ayuda la vegetación y los árboles en las ciudades durante las olas de calor?',
    opciones: ['Retienen más calor aumentando la sensación térmica', 'Refrescan el aire de forma natural mediante la evapotranspiración y proveen sombra protectora', 'Bloquean el viento refrescante costero', 'Aumentan la humedad de las calles'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué consume más agua en el baño de un hogar promedio?',
    opciones: ['Lavarse las manos en el lavamanos', 'El inodoro convencional por descarga completa y la ducha', 'Cepillarse los dientes', 'El espejo goteando'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál de los siguientes materiales NO se puede reciclar en los puntos limpios convencionales?',
    opciones: ['Botella plástica de refresco PET 1', 'Caja de cartón corrugado', 'Servilletas de papel sucias y pañuelos desechables usados', 'Lata de refresco de aluminio'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué efecto tiene la deforestación (tala indiscriminada de bosques) en el cambio climático?',
    opciones: ['Permite que el sol llegue mejor al suelo acelerando el crecimiento floral', 'Reduce los sumideros naturales de carbono, acumulando más CO2 en la atmósfera', 'Refresca el ambiente eliminando árboles viejos', 'Aumenta el oxígeno en el aire local'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué es el consumo de energía en espera (Standby)?',
    opciones: ['La energía que consume un artefacto mientras se usa', 'La energía silenciosa que consume un equipo apagado pero enchufado listo para encender con control remoto', 'La energía acumulada en paneles solares de noche', 'La energía que gasta el medidor general'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué tipo de dispositivo en stand-by consume más energía silenciosa?',
    opciones: ['Televisor LED apagado', 'Decodificador de TV por cable encendido o en espera activa', 'Cargador de tablet sin conectar', 'Consola de videojuegos completamente desenchufada'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué es la huella hídrica?',
    opciones: ['La marca física del agua al escurrir en el suelo', 'El volumen total de agua dulce que se utiliza para producir los bienes y servicios que consumimos', 'El nivel de evaporación en lagos costeros', 'La cantidad de lluvia caída en un año en m³'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Aproximadamente cuánta agua se necesita para producir una sola taza de café considerando el cultivo, transporte y proceso?',
    opciones: ['Una taza de agua únicamente', 'Alrededor de 10 litros', 'Aproximadamente 140 litros de agua', 'Más de 500 litros de agua'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Cuánta agua virtual se estima que consume fabricar un solo pantalón de jeans de mezclilla de algodón?',
    opciones: ['Cerca de 100 litros', 'Alrededor de 1.000 litros', 'Hasta 10.000 litros de agua dulce', 'Más de 100.000 litros de agua'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es la forma más eficiente de usar el lavavajillas o lavaplatos?',
    opciones: ['Hacerlo funcionar tres veces al día con pocas tazas sueltas', 'Esperar a acumular la carga completa para optimizar el agua y la electricidad', 'Lavar cada plato por separado usando agua caliente continua', 'No influye en el consumo'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Qué color de contenedor se asocia convencionalmente para depositar plásticos en puntos limpios chilenos?',
    opciones: ['Verde', 'Azul', 'Amarillo', 'Gris oscuro'],
    correcta: 2,
  ),
  TriviaQuestion(
    pregunta: '¿Qué ley en Chile promueve la Gestión de Residuos, la Responsabilidad Extendida del Productor y el Fomento al Reciclaje?',
    opciones: ['Ley de Seguridad Eléctrica', 'Ley REP (Ley 20.920)', 'Ley de Aguas Potables', 'Ley de Bosque Nativo Sustentable'],
    correcta: 1,
  ),
  TriviaQuestion(
    pregunta: '¿Cuál es el beneficio de la Responsabilidad Extendida del Productor (REP) en Chile?',
    opciones: ['Obliga a los importadores y fabricantes a financiar el reciclaje de los productos que colocan en el mercado', 'Reduce los sueldos en industrias plásticas', 'Subsidia la importación de plástico', 'Permite botar envases en la vía pública'],
    correcta: 0,
  ),
];
