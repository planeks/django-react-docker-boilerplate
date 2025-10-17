from django.conf import settings
from django.shortcuts import render


def index(request):
    return render(
        request,
        "index.html",
        {
            "VITE_DEV_SERVER_HOST": settings.VITE_DEV_SERVER_HOST,
            "DEBUG": settings.DEBUG,
        }
    )
