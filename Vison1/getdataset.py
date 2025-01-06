from roboflow import Roboflow
rf = Roboflow(api_key="DgF7TscAnuDd5tFhNvP3")
project = rf.workspace("draikaiz").project("datn-dirag")
version = project.version(10)
dataset = version.download("yolov11")
                
                