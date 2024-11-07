global g_selectedObject = undefined
global g_drawingMode = false
global g_vertexDistance = 10.0
global g_emptyMeshObject = undefined
global g_isPolygonCreating = false -- Переменная для отслеживания состояния
global g_surfaceOffset = 5.0 -- Новый параметр расстояния от поверхности
global g_normalDirection = [0,1,0]
global clickCount = 0


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
			local vertexCount = getNumVerts g_emptyMeshObject -- Получаем текущее количество вертексов 
			local faceCount = getNumFaces g_emptyMeshObject -- Получаем текущее количество граней 
			 
			print ("Текущее количество вертексов: " + vertexCount as string) -- Отладочный вывод 
			print ("Текущее количество граней: " + faceCount as string) -- Отладочный вывод 

			-- Проверка, что есть как минимум 4 вершины 
			if vertexCount >= 4 then 
			( 
				-- Увеличиваем количество граней на 2 
				setNumFaces g_emptyMeshObject (faceCount + 2) true 

				-- Устанавливаем индексы для новых граней 
				local firstVertexIndex = vertexCount - 3 -- Индекс первого вертекса (1) 
				local secondVertexIndex = vertexCount - 2 -- Индекс второго вертекса (2) 
				local thirdVertexIndex = vertexCount - 1 -- Индекс третьего вертекса (3) 
				local fourthVertexIndex = vertexCount -- Индекс четвертого вертекса (4) 
				 
				-- Создаем два треугольника с обратным порядком для направления нормалей вверх 
				setFace g_emptyMeshObject (faceCount + 1) thirdVertexIndex secondVertexIndex fourthVertexIndex -- Первый треугольник: вершины 3, 2, 1 
				setFace g_emptyMeshObject (faceCount + 2) thirdVertexIndex firstVertexIndex secondVertexIndex -- Второй треугольник: вершины 3, 4, 2 

				print ("Созданы грани, соединяющие вертексы: " + thirdVertexIndex as string + ", " + secondVertexIndex as string + ", " + firstVertexIndex as string + " и " + thirdVertexIndex as string + ", " + fourthVertexIndex as string + ", " + secondVertexIndex as string) -- Отладочный вывод 

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


-- Функция для получения нормали поверхности в заданной точке
fn getNormalAt hitPos node =
( 
	-- Проверяем, что узел (node) не является неопределённым и не был удалён 
	if (node != undefined and not isDeleted node) then 
	( 
		print("Node: " + (node as string)) -- Отладочный вывод для проверки узла 

		-- Получаем позицию узла 
		local nodePos = node.position -- Получаем позицию узла 
		 
		-- Получаем максимальную Z координату узла 
		local nodeMaxZ = node.max.z -- максимальная Z координата узла 
		 
		local rayStartPos = getViewportPosition()  -- Позиция, откуда будет запущен луч 
		print("Ray Start Position: " + (rayStartPos as string)) -- Отладочный вывод позиции старта луча 

		-- Вычисляем направление луча от rayStartPos к hitPos 
		local rayDirection = normalize (hitPos - rayStartPos) -- Направление луча 
		print("Ray Direction: " + (rayDirection as string)) -- Отладочный вывод направления луча 

		-- Создаем луч с началом в rayStartPos и направлением rayDirection 
		local myRay = ray rayStartPos rayDirection -- Создаем луч 
		print("Ray Created: " + (myRay as string)) -- Проверяем, что луч создан 

		-- Визуализация точек для дебага 
		-- local startPoint = dummy pos:rayStartPos  -- Точка старта (rayStartPos) 
		--  startPoint.name = "Ray Start"  -- Устанавливаем имя 
		--  local endPoint = dummy pos:(rayStartPos + rayDirection * 250)  -- Точка на расстоянии 250 в направлении rayDirection 
		--  endPoint.name = "Ray End"  -- Устанавливаем имя 
		 
		-- Выполняем проверку пересечения с объектом node 
		local intersection = intersectRay node myRay -- Проверка пересечения 
		print("Intersection: " + (intersection as string)) -- Вывод результата пересечения 

		-- Проверка результата пересечения 
		if intersection != undefined then 
		( 
			-- Извлекаем позицию пересечения и нормаль 
			local hitPosition = intersection.pos -- Позиция пересечения 
			local intersectionNormal = intersection.dir -- Нормаль 

			print("Hit Position: " + (hitPosition as string)) -- Отладочный вывод позиции пересечения 
			print("Normal found: " + (intersectionNormal as string)) -- Отладочный вывод нормали 
			return intersectionNormal -- Возвращаем нормаль 
		) 
		else 
		( 
			print("No intersection found, returning default normal.") -- Сообщение об отсутствии пересечения 
			return [0, 0, 1] -- Возвращаем стандартную нормаль (например, по оси Z) 
		) 
	) 
	else 
	( 
		print("Node is undefined or deleted.") -- Сообщение об ошибке 
		return [0, 0, 1] -- Возвращаем стандартную нормаль 
	)
)





fn getViewportPosition =
( 
	-- Get the view transformation matrix 
	local viewTM = getViewTM()  
	print("viewTM: " + (viewTM as string)) -- Отладочный вывод позиции старта луча 
	-- Invert the matrix to get the world coordinates 
	local coordSysTM = Inverse(viewTM) 
	print("coordSysTM: " + (coordSysTM as string)) -- Отладочный вывод позиции старта луча 
	-- The position of the viewport (camera) is in the fourth row (row 4) 
	local viewportPos = coordSysTM.row4 
	print("viewportPos: " + (viewportPos as string)) 
	return viewportPos
)





fn createVerticesAtHitPosition hitPos normalDirectionRotate =
( 
	if g_emptyMeshObject != undefined then 
	( 
		local vertexCount = getNumVerts g_emptyMeshObject -- Получаем текущее количество вертексов 
		print ("Текущее количество вертексов: " + vertexCount as string) -- Отладочный вывод 

		-- Увеличиваем количество вертексов на 2 с сохранением топологии 
		local newVertexCount = vertexCount + 2 
		setNumVerts g_emptyMeshObject newVertexCount true -- true - сохраняет топологию 

		-- Получаем нормаль поверхности в точке попадания 
		local normal = getNormalAt hitPos g_selectedObject -- Эта функция должна быть реализована, чтобы получить нормаль 
		print("Computed normal: " + (normal as string)) 
		 
		-- Увеличиваем координаты вертексов на значение g_surfaceOffset по нормали 
		local firstVertexIndex = vertexCount + 1 
		local secondVertexIndex = vertexCount + 2 
		 
		print("Normal: " + (normal as string)) 
		print("normalDirectionRotate: " + (normalDirectionRotate as string))

		-- Normalize the normalDirectionRotate and normal vectors
		local normalDirectionRotateNormalized = normalize(normalDirectionRotate)
		local normalNormalized = normalize(normal)

		-- Calculate g_normalDirection as the cross-product between the normalized normalDirectionRotate and normal vectors, then normalize
		g_normalDirection = normalDirectionRotate;
		print("Perpendicular direction (g_normalDirection): " + (g_normalDirection as string))

		-- Calculate perpendicularNormal by crossing normal with g_normalDirection, then normalize
		local perpendicularNormal = normalize(cross normal g_normalDirection)
		print("Perpendicular direction: " + (perpendicularNormal as string))

		-- Calculate perpendicularRayPosition
		local perpendicularRayPosition = hitPos + (normalNormalized * g_surfaceOffset) + (perpendicularNormal * g_vertexDistance / 2.0)
		print("perpendicularRayPosition: " + (perpendicularRayPosition as string))

		
		setVert g_emptyMeshObject firstVertexIndex perpendicularRayPosition -- Вертекс 1 

		
		local perpendicularNormalInverse = normalize(cross normal -g_normalDirection) 
		 
		-- Позиция второго перпендикулярного луча 
		local perpendicularRayPositionInverse = hitPos + (normal * g_surfaceOffset) + (perpendicularNormalInverse * g_vertexDistance / 2.0) 
			
			 
		print("perpendicularRayPositionInverse: " + (perpendicularRayPositionInverse as string)) -- Отладочный вывод 
		setVert g_emptyMeshObject secondVertexIndex perpendicularRayPositionInverse
		 
		print("Созданы новые вертексы на позициях: " + (hitPos + (normal * g_surfaceOffset)) as string) -- Отладочный вывод 
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
			 
			print ("клик: " + clickCount as string) 
			if obj != undefined then 
			( 
				if clickCount == 0 then 
				( 
					hitPosTest = ir.pos 
					clickCount += 1 
					print ("Первый клик по поверхности: " + hitPos as string) 
				) 
				else if clickCount == 1 then 
				( 
					hitPosSecondTest = ir.pos 
					clickCount += 1 
					print ("Второй клик по поверхности: " + hitPosSecondTest as string) 
					 
					-- Вычисляем вектор нормали от hitPos к hitPosSecond 
					local normalVector = hitPosSecondTest - hitPosTest 
					local normal = normalize normalVector 
					print ("Нормаль от первого клика ко второму: " + normal as string) 
					 
					-- Сбросим переменные для следующего использования 
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
	spinner spVertexDistance "Расстояние между вертексами:" range: [0,100,10] type:#float fieldWidth:80 

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
