from django.conf import settings
from django.views.generic import TemplateView


class IndexView(TemplateView):
    template_name = "index.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["VITE_DEV_SERVER_HOST"] = settings.VITE_DEV_SERVER_HOST
        context["DEBUG"] = settings.DEBUG
        return context
