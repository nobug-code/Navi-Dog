from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from ultralytics import YOLO
from PIL import Image
import io
import os

app = FastAPI()

# Load the trained YOLO model
model = YOLO('./best.pt')  # Replace with the path to your trained model

@app.post("/detect_objects")
async def detect_objects(file: UploadFile = File(...)):
    """
    Endpoint to detect objects in an uploaded image using a YOLO model.

    Args:
    - file (UploadFile): The uploaded image file.

    Returns:
    - JSONResponse: A JSON response containing detected classes, coordinates, and confidence scores.
    """
    # Read the image file
    image_data = await file.read()
    image = Image.open(io.BytesIO(image_data))

    # Perform inference
    results = model(image)
    print(f"image_result >> {results}")
    # Extract detected classes and coordinates
    detected_objects = []
    for result in results:
        for box in result.boxes:
            print(f"box >> {box}")
            class_name = model.names[int(box.cls)]
            coordinates = box.xyxy[0].tolist()  # xyxy format: [xmin, ymin, xmax, ymax]
            confidence = box.conf[0].item()  # Confidence score
            detected_objects.append({
                'class': class_name,
                'coordinates': coordinates,
                'confidence': confidence,
                'message' : class_name,
            })

    return JSONResponse(content={"detected_objects": detected_objects})

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, http="h11")

# Command to run the server:
# uvicorn main:app —host 0.0.0.0 —port 8000


