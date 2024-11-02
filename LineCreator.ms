global g_selectedObject = undefined
global g_drawingMode = false
global g_vertexDistance = 10.0
global g_emptyMeshObject = undefined
global g_isPolygonCreating = false  -- Переменная для отслеживания состояния
global g_surfaceOffset = 5.0  -- Новый параметр расстояния от поверхности
fn createEmptyMeshObject =
(
    g_emptyMeshObject = mesh()
    g_emptyMeshObject.name = "MeshVertexObject"
    print ("Создан пустой объект: " + g_emptyMeshObject.name)
    setNumVerts g_emptyMeshObject 0
)

fn createPolygonBetweenVertices =
(
    if g_emptyMeshObject != undefined then
    (
        if g_isPolygonCreating then
        (
            local vertexCount = getNumVerts g_emptyMeshObject  -- Получаем текущее количество вертексов
            local faceCount = getNumFaces g_emptyMeshObject  -- Получаем текущее количество граней
            
            print ("Текущее количество вертексов: " + vertexCount as string)  -- Отладочный вывод
            print ("Текущее количество граней: " + faceCount as string)  -- Отладочный вывод

            -- Проверка, что есть как минимум 4 вершины
            if vertexCount >= 4 then
            (
                -- Увеличиваем количество граней на 2
                setNumFaces g_emptyMeshObject (faceCount + 2) true

                -- Устанавливаем индексы для новых граней
                local firstVertexIndex = vertexCount - 3  -- Индекс первого вертекса (1)
                local secondVertexIndex = vertexCount - 2  -- Индекс второго вертекса (2)
                local thirdVertexIndex = vertexCount - 1  -- Индекс третьего вертекса (3)
                local fourthVertexIndex = vertexCount     -- Индекс четвертого вертекса (4)
                
                -- Создаем два треугольника с обратным порядком для направления нормалей вверх
                setFace g_emptyMeshObject (faceCount + 1) thirdVertexIndex secondVertexIndex firstVertexIndex  -- Первый треугольник: вершины 3, 2, 1
                setFace g_emptyMeshObject (faceCount + 2) thirdVertexIndex fourthVertexIndex secondVertexIndex  -- Второй треугольник: вершины 3, 4, 2

                print ("Созданы грани, соединяющие вертексы: " + thirdVertexIndex as string + ", " + secondVertexIndex as string + ", " + firstVertexIndex as string + " и " + thirdVertexIndex as string + ", " + fourthVertexIndex as string + ", " + secondVertexIndex as string)  -- Отладочный вывод

                 -- Установка видимости ребер
                -- Ребро между 1 и 3 (первый треугольник)
                setEdgeVis g_emptyMeshObject (faceCount + 1) 3 true
                -- Ребро между 2 и 4 (второй треугольник)
                setEdgeVis g_emptyMeshObject (faceCount + 2) 2 true
                -- Ребро между 1 и 2 (первый треугольник)
                setEdgeVis g_emptyMeshObject (faceCount + 1) 2 true
                -- Ребро между 3 и 4 (второй треугольник)
                setEdgeVis g_emptyMeshObject (faceCount + 2) 1 true


                print ("Установлена видимость ребер для последнего полигона.")

                -- Обновляем объект, чтобы изменения стали видимыми
                update g_emptyMeshObject  
            )
            else
            (
                print "Недостаточно вертексов для создания полигона (нужно минимум 4)."
            )
        )
        else
        (
            -- Если это первое нажатие, переключаем флаг для создания полигона
            g_isPolygonCreating = true
            print "Нажмите еще раз для создания полигона."
        )
    )
    else
    (
        print "Сначала создайте пустой объект."
    )
)







fn createVerticesAtHitPosition hitPos =
(
    if g_emptyMeshObject != undefined then
    (
        local vertexCount = getNumVerts g_emptyMeshObject  -- Получаем текущее количество вертексов
        print ("Текущее количество вертексов: " + vertexCount as string)  -- Отладочный вывод

        -- Увеличиваем количество вертексов на 2 с сохранением топологии
        local newVertexCount = vertexCount + 2
        setNumVerts g_emptyMeshObject newVertexCount true  -- true - сохраняет топологию

        -- Устанавливаем координаты для новых вертексов
        local firstVertexIndex = vertexCount + 1
        local secondVertexIndex = vertexCount + 2

        -- Устанавливаем координаты новых вертексов
        setVert g_emptyMeshObject firstVertexIndex hitPos  -- Первый вертекс
        setVert g_emptyMeshObject secondVertexIndex (hitPos + [g_vertexDistance, 0, 0])  -- Второй вертекс, смещенный на заданное расстояние

        print ("Добавлены новые вертексы: " + firstVertexIndex as string + ", " + secondVertexIndex as string)  -- Отладочный вывод

        -- Обновляем объект, чтобы изменения стали видимыми
        update g_emptyMeshObject  

        -- Проверяем позиции всех вертексов после добавления новых
        local finalVertexCount = getNumVerts g_emptyMeshObject
        for i = 1 to finalVertexCount do
        (
            local vertPos = getVert g_emptyMeshObject i
            print ("Вертекс " + i as string + " имеет позицию: " + vertPos as string)
        )

        -- Проверяем, нужно ли создать грань после добавления новых вершин
        createPolygonBetweenVertices()
    )
    else
    (
        print "Сначала создайте пустой объект."
    )
)

fn mouseTrackCallback msg ir obj faceNum shift ctrl alt =
(
    if g_drawingMode then
    (
        if msg == #mousePoint then
        (
            if obj != undefined then
            (
                local hitPos = ir.pos
                print ("Клик по поверхности: " + hitPos as string)
                createVerticesAtHitPosition hitPos
            )
            else
            (
                print "Кликнули, но объект не определен."
            )
        )
    )
    return #continue
)

fn pickObjectAndSet =
(
    g_selectedObject = pickObject()
    if g_selectedObject != undefined then
    (
        print ("Выбран объект: " + g_selectedObject.name)
    )
)

fn enableDrawingMode =
(
    g_drawingMode = true
    print "Режим рисования включен. Кликните по объекту для создания вертексов."
    mouseTrack on:g_selectedObject prompt:"Кликните по поверхности объекта." trackCallback:mouseTrackCallback
)

fn disableDrawingMode =
(
    g_drawingMode = false
    print "Режим рисования выключен."
    mouseTrack off
)

rollout drawingRollout "Режим рисования"
(
    button btnCreateEmpty "Создать пустой объект" width:150 height:30
    button btnPick "Выбрать объект" width:150 height:30
    button btnEnable "Включить режим рисования" width:150 height:30
    button btnDisable "Выключить режим рисования" width:150 height:30
    spinner spVertexDistance "Расстояние между вертексами:" range:[0,100,10] type:#float fieldWidth:80

    on btnCreateEmpty pressed do
    (
        createEmptyMeshObject()
    )

    on btnPick pressed do
    (
        pickObjectAndSet()
    )

    on btnEnable pressed do
    (
        enableDrawingMode()
    )

    on btnDisable pressed do
    (
        disableDrawingMode()
    )

    on spVertexDistance changed newValue do
    (
        g_vertexDistance = newValue
        print ("Расстояние между вертексами обновлено: " + newValue as string)
    )
)

createDialog drawingRollout
