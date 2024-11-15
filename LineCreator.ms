global g_selectedObject = undefined
global g_drawingMode = false
global g_vertexDistance = 10.0
global g_emptyMeshObject = undefined
global g_isPolygonCreating = false
global g_surfaceOffset = 5.0
global g_normalDirection = [0,1,0]
global clickCount = 0
global g_selectedMaterial = undefined

global g_uvOffsetX = 0.0
global g_uvOffsetY = 0.036 
global g_second_uvOffsetY = 0.011

fn createEmptyMeshObject =
( 	
	g_emptyMeshObject = mesh()  
	g_emptyMeshObject.name = "MeshVertexObject" 
	setNumVerts g_emptyMeshObject 0
	if g_selectedMaterial != undefined then
	(
		g_emptyMeshObject.material = g_selectedMaterial
	)
)

fn createPolygonBetweenVertices =
( 
	if g_emptyMeshObject != undefined then 
	( 
		if g_isPolygonCreating then 
		( 
			local vertexCount = getNumVerts g_emptyMeshObject
			local faceCount = getNumFaces g_emptyMeshObject

			-- Проверка, что есть как минимум 4 вершины 
			if vertexCount >= 4 then 
			( 
				-- Увеличиваем количество граней на 2 
				setNumFaces g_emptyMeshObject (faceCount + 2) true 

				local firstVertexIndex = vertexCount - 3
				local secondVertexIndex = vertexCount - 2
				local thirdVertexIndex = vertexCount - 1
				local fourthVertexIndex = vertexCount

				-- Создаем два треугольника
				setFace g_emptyMeshObject (faceCount + 1) thirdVertexIndex secondVertexIndex fourthVertexIndex
				setFace g_emptyMeshObject (faceCount + 2) thirdVertexIndex firstVertexIndex secondVertexIndex
			
				-- Установка видимости ребер
				setEdgeVis g_emptyMeshObject (faceCount + 1) 3 true
				setEdgeVis g_emptyMeshObject (faceCount + 2) 2 true
				setEdgeVis g_emptyMeshObject (faceCount + 1) 2 true
				setEdgeVis g_emptyMeshObject (faceCount + 2) 1 true
			
				
				meshop.defaultMapFaces g_emptyMeshObject 1
				meshop.setMapVert g_emptyMeshObject 1 (faceCount + 1)[0 + faceCount,g_uvOffsetY,0]
				meshop.setMapVert g_emptyMeshObject 1 (faceCount + 2) [0 + faceCount,g_second_uvOffsetY,0]
				meshop.setMapVert g_emptyMeshObject 1 (faceCount + 3) [1 + faceCount,g_uvOffsetY,0]
				meshop.setMapVert g_emptyMeshObject 1 (faceCount + 4) [1 + faceCount,g_second_uvOffsetY,0]
				
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
			g_isPolygonCreating = true 
			print "Нажмите еще раз для создания полигона." 
		) 
	) 
	else 
	( 
		print "Сначала создайте пустой объект." 
	)
)

fn getNormalAt hitPos node =
( 
	if (node != undefined and not isDeleted node) then 
	( 
		local nodePos = node.position
		local nodeMaxZ = node.max.z

		local rayStartPos = getViewportPosition()
		local rayDirection = normalize (hitPos - rayStartPos)

		local myRay = ray rayStartPos rayDirection
		local intersection = intersectRay node myRay

		if intersection != undefined then 
		( 
			local hitPosition = intersection.pos
			local intersectionNormal = intersection.dir
			return intersectionNormal
		) 
		else 
		( 
			return [0, 0, 1]
		) 
	) 
	else 
	( 
		return [0, 0, 1]
	)
)
fn saveSettings = 
(
    local iniFile = getDir #userScripts + "\\settings.ini"
    setINISetting iniFile "Settings" "VertexDistance" (g_vertexDistance as string)
    setINISetting iniFile "Settings" "SurfaceOffset" (g_surfaceOffset as string)
)
fn loadSettings =
(
    local iniFile = getDir #userScripts + "\\settings.ini"
    if doesFileExist iniFile then 
    (
        g_vertexDistance = (getINISetting iniFile "Settings" "VertexDistance") as float
        g_surfaceOffset = (getINISetting iniFile "Settings" "SurfaceOffset") as float
    )
)

fn getViewportPosition =
( 
	local viewTM = getViewTM()  
	local coordSysTM = Inverse(viewTM)
	local viewportPos = coordSysTM.row4 
	return viewportPos
)

fn createVerticesAtHitPosition hitPos normalDirectionRotate =
(
    if g_emptyMeshObject != undefined then
    (
        select g_emptyMeshObject
        max modify mode
        subObjectLevel = 1

        local vertexCount = getNumVerts g_emptyMeshObject
        local newVertexCount = vertexCount + 2
        setNumVerts g_emptyMeshObject newVertexCount true

        local normal = getNormalAt hitPos g_selectedObject
        local firstVertexIndex = vertexCount + 1
        local secondVertexIndex = vertexCount + 2

        local normalDirectionRotateNormalized = normalize(normalDirectionRotate)
        local normalNormalized = normalize(normal)

        g_normalDirection = normalDirectionRotate
        local perpendicularNormal = normalize(cross normal g_normalDirection)

        -- Если заданы последние вершины, продолжаем от них
        if g_lastVertexIndex1 != undefined and g_lastVertexIndex2 != undefined then
        (
            setVert g_emptyMeshObject firstVertexIndex (getVert g_continuationObject g_lastVertexIndex1)
            setVert g_emptyMeshObject secondVertexIndex (getVert g_continuationObject g_lastVertexIndex2)
        )
        else
        (
            -- Иначе создаем вершины от текущего положения
            local perpendicularRayPosition = hitPos + (normalNormalized * g_surfaceOffset) + (perpendicularNormal * g_vertexDistance / 2.0)
            setVert g_emptyMeshObject firstVertexIndex perpendicularRayPosition

            local perpendicularNormalInverse = normalize(cross normal -g_normalDirection)
            local perpendicularRayPositionInverse = hitPos + (normal * g_surfaceOffset) + (perpendicularNormalInverse * g_vertexDistance / 2.0)
            setVert g_emptyMeshObject secondVertexIndex perpendicularRayPositionInverse
        )

        -- Сохраняем индексы последних двух вершин для продолжения рисования
        g_lastVertexIndex1 = firstVertexIndex
        g_lastVertexIndex2 = secondVertexIndex

    )
    else
    (
        print "Сначала создайте пустой объект."
    )

    createPolygonBetweenVertices()
)

global hitPosTest = undefined
global hitPosSecondTest = undefined

fn mouseTrackCallback msg ir obj faceNum shift ctrl alt =
( 
	if g_drawingMode then 
	( 
		if msg == #mousePoint then 
		( 
			if obj != undefined then 
			( 
				if clickCount == 0 then 
				( 
					hitPosTest = ir.pos 
					clickCount += 1 
				) 
				else if clickCount == 1 then 
				( 
					hitPosSecondTest = ir.pos 
					clickCount += 1 
					local normalVector = hitPosSecondTest - hitPosTest 
					local normal = normalize normalVector 
					createVerticesAtHitPosition hitPosTest normal 
					clickCount = 0 
					hitPosTest = undefined 
					hitPosSecondTest = undefined 
				) 
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
fn selectContinuationObject =
(
    g_continuationObject = pickObject()
    if g_continuationObject != undefined then
    (
        print ("Выбран объект для продолжения рисования: " + g_continuationObject.name)

        -- Получение количества вершин
        local vertexCount = getNumVerts g_continuationObject
        if vertexCount >= 2 then
        (
            -- Устанавливаем последние две вершины как начальные
            g_lastVertexIndex1 = vertexCount - 1
            g_lastVertexIndex2 = vertexCount
            print ("Последние вершины выбраны: " + g_lastVertexIndex1 as string + ", " + g_lastVertexIndex2 as string)
        )
        else
        (
            print "Недостаточно вершин для продолжения (нужно минимум 2)."
            g_lastVertexIndex1 = undefined
            g_lastVertexIndex2 = undefined
        )
    )
    else
    (
        print "Не удалось выбрать объект."
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
	print "Режим рисования выключен. Последние вершины сохранены для продолжения." 
	mouseTrack off
)

rollout drawingRollout "Line Creator" width:224 height:208
( 
	button 'btnCreateEmpty' "Create empty obj" pos:[8,8] width:100 height:30 align:#left
	button 'btnPick' "Pick surface obj" pos:[8,40] width:100 height:30 align:#left
	button 'btnEnable' "On edit mode" pos:[8,72] width:100 height:30 align:#left
	button 'btnDisable' "Off edit mode" pos:[8,104] width:100 height:30 align:#left
	button 'btnSelectContinuation' "Select obj to continue" pos:[8,136] width:100 height:30 align:#left
	materialButton 'matSlot' "Select Material" pos:[8,168] width:100 height:30 align:#left
	label 'lblEmptyObjectName' "Name :" pos:[120,8] width:100 height:30 align:#left
	label 'lblSelectedObjectName' "Select Obj:" pos:[120,40] width:100 height:30 align:#left
	label 'lblMaterialName' "Select Material : None   " pos:[119,168] width:100 height:30 align:#left
	groupBox 'VertexSettings' "VertexSettings" pos:[112,64] width:100 height:96 align:#left
	spinner 'spVertexDistance' "Wide line" pos:[120,87] width:44 height:16 align:#left
	spinner 'spVertexOffset' "Offset   " pos:[120,112] width:51 height:16 align:#left
	-- Event handler for material selection
	on matSlot picked mat do
	(
		g_selectedMaterial = mat  -- Store the picked material in the global variable
		print ("Материал выбран: " + g_selectedMaterial.name)
		lblMaterialName.text = "Выбранный материал: " + g_selectedMaterial.name  -- Display material name
		if g_emptyMeshObject != undefined then
		(
			g_emptyMeshObject.material = g_selectedMaterial  -- Apply the selected material to the mesh if it exists
			update g_emptyMeshObject
		)
	)

	-- Event handler for picking an object
	on btnPick pressed do
	( 
		pickObjectAndSet()  -- Function to pick an object and set it to g_selectedObject
		if g_selectedObject != undefined then
		(
			lblSelectedObjectName.text = "Выбранный объект: " + g_selectedObject.name  -- Display selected object name
		)
	) 
	
	on btnCreateEmpty pressed do 
	( 
		createEmptyMeshObject() 
		if g_emptyMeshObject != undefined then
		(
			lblEmptyObjectName.text = "Create obj: " + g_emptyMeshObject.name  -- Display selected object name
		)
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
		saveSettings()
	)
	
	on spVertexOffset changed newValue do 
	( 
		g_surfaceOffset = newValue
		saveSettings()
	)
)

-- Function to pick and set the selected object
fn pickObjectAndSet =
( 
	g_selectedObject = pickObject()  
	if g_selectedObject != undefined then 
	( 
		print ("Выбран объект: " + g_selectedObject.name) 
	)
)

loadSettings()  -- Load saved values at the start
createDialog drawingRollout
drawingRollout.spVertexDistance.value = g_vertexDistance  -- Set spinner to loaded value
drawingRollout.spVertexOffset.value = g_surfaceOffset     -- Set spinner to loaded value


